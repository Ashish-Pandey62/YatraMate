from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from .models import CustomUser, Transaction, Tour, TokenRecord
from .serializers import CustomUserSerializer, TransactionSerializer, SecretKeyUpdateSerializer,QRCodeDataSerializer,TourSerializer
from rest_framework import status
from cryptography.hazmat.primitives import serialization

import jwt
from django.conf import settings
from django.utils import timezone
from rest_framework.decorators import api_view, permission_classes
from datetime import timedelta
from datetime import datetime
from decimal import Decimal
from django.db import transaction



class UserDetailsView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        serializer = CustomUserSerializer(user)
        return Response(serializer.data)


class TransactionHistoryView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        
        if user.is_traveler:
            transactions = Transaction.objects.filter(traveler=user)
        elif user.is_conductor:
            transactions = Transaction.objects.filter(conductor=user)
        else:
            return Response({"detail": "User does not have access to transaction history."}, status=403)

        serializer = TransactionSerializer(transactions, many=True)
        return Response(serializer.data)
    
    
class UpdateSecretKeyView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        user = request.user
        serializer = SecretKeyUpdateSerializer(data=request.data)
        
        if serializer.is_valid():
            serializer.update(user, serializer.validated_data)
            return Response({"detail": "Secret key updated successfully."}, status=status.HTTP_200_OK)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    


# validation of qr codee

JWT_SECRET_KEY = settings.SECRET_KEY

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def validate_qr_code(request):
    try:
        passenger_token = request.data.get("token")
        if not passenger_token:
            return Response({"status": "failed", "message": "Token missing in request"}, status=status.HTTP_400_BAD_REQUEST)

        passenger_data = jwt.decode(
            passenger_token,
            options={"verify_signature": False} 
        )
        
        passenger_username = passenger_data.get("sub")
        amount = Decimal(passenger_data.get("price", 0))
        
        
        passenger = CustomUser.objects.get(username=passenger_username)

        if TokenRecord.objects.filter(token=passenger_token, user=passenger).exists():
            return Response({"status": "failed", "message": "Token has already been used"}, status=status.HTTP_400_BAD_REQUEST)
        
        passenger_secret_key = passenger.secret_key
        public_key = serialization.load_pem_public_key(passenger_secret_key.encode())
        # print(passenger_token,passenger_data, passenger_secret_key)
  
        verified_data = jwt.decode(
            passenger_token,
            public_key,
            algorithms=["RS256"]
        )
        

        exp_timestamp = verified_data.get("exp")
        iat_timestamp = verified_data.get("iat")
        current_time = timezone.now().timestamp() * 1000
        
        if iat_timestamp > current_time or exp_timestamp < current_time:
            return Response({"status": "failed", "message": "Invalid token"}, status=status.HTTP_401_UNAUTHORIZED)
    

        if passenger.balance < amount:
            return Response({"status": "failed", "message": "Insufficient balance"}, status=status.HTTP_400_BAD_REQUEST)

        conductor = request.user
        if not conductor.is_conductor:
            return Response({"status": "failed", "message": "Only conductors can validate QR codes"}, status=status.HTTP_403_FORBIDDEN)

        with transaction.atomic():
            passenger.balance -= amount
            conductor.balance += amount
            passenger.save()
            conductor.save()
            
            
            #ashish transaction create garya khaiiii
            #  chowk tira 
            
            Transaction.objects.create(
            amount=amount,
            transaction_date=timezone.now(),
            status="Completed",  
            traveler=passenger,
            conductor=conductor,
            tour=Tour.objects.filter(conductor=conductor, is_active=True).first()
                 )
            
            TokenRecord.objects.create(
                token=passenger_token,
                user=passenger,
                expires_at=timezone.now() + timedelta(minutes=15)
            )
            
        return Response({"status": "success", "message": "QR code validated and balance updated"}, status=status.HTTP_200_OK)
    
    except jwt.ExpiredSignatureError:
        return Response({"status": "failed", "message": "Token has expired"}, status=status.HTTP_401_UNAUTHORIZED)
    except jwt.InvalidTokenError:
        return Response({"status": "failed", "message": "Invalid token"}, status=status.HTTP_401_UNAUTHORIZED)
    except CustomUser.DoesNotExist:
        return Response({"status": "failed", "message": "User not found"}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({"status": "failed", "message": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)



#  activating the tour
@api_view(['POST'])
@permission_classes([IsAuthenticated])  
def activate_tour(request):
    try:
        if request.user.user_type != 'conductor':
            return Response({"status": "failed", "message": "Only conductors can activate a tour"}, status=status.HTTP_403_FORBIDDEN)
        
        active_user_tour = Tour.objects.filter(conductor=request.user, is_active=True)
        if active_user_tour.exists():
            return Response({
                "status": "failed",
                "message": "User already has an active tour"
            }, status=status.HTTP_400_BAD_REQUEST)
        
        source_lat = request.data.get("source_lat")
        source_lng = request.data.get("source_lng")
        destination_lat = request.data.get("destination_lat")
        destination_lng = request.data.get("destination_lng")
        # if not source or not destination:
        #     return Response({"status": "failed", "message": "Source and destination are required"}, status=status.HTTP_400_BAD_REQUEST)
        
        tour = Tour.objects.create(
            is_active=True,
            latitude=10.0,
            longitude=10.0,
            conductor=request.user,
            source_lat=source_lat,
            source_lng=source_lng,
            destination_lat=destination_lat,
            destination_lng=destination_lng
        )
        
        transactions = Transaction.objects.filter(tour=tour)
        
        tour_serializer = TourSerializer(tour)
        transaction_serializer = TransactionSerializer(transactions, many=True)
        
        print("Hit hit hit")
        
        return Response({
            "message": "Tour activated successfully",
            "tour_data": {
                **tour_serializer.data,
                "transactions": transaction_serializer.data  
            }  
        }, status=status.HTTP_201_CREATED)
    
    except Exception as e:
        return Response({
            "status": "failed",
            "message": str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)



@api_view(['GET'])
@permission_classes([IsAuthenticated])
def check_active_tour(request):
    try:
        if request.user.user_type != 'conductor':
            return Response({"status": "failed", "message": "Only conductors can activate a tour"}, status=status.HTTP_403_FORBIDDEN)
        
        active_user_tour = Tour.objects.filter(conductor=request.user,is_active=True)
        print(active_user_tour.first())
        
        if active_user_tour.exists():
            
            tour = active_user_tour.first()
            transactions = Transaction.objects.filter(tour=tour)
            
            
            tour_serializer = TourSerializer(tour)
            transaction_serializer = TransactionSerializer(transactions, many=True)
            
            return Response({
                "status": "success",
                "message": "An active tour is found",
                "is_active": True,
                "tour_data": {
                    **tour_serializer.data,
                    "transactions": transaction_serializer.data  
                }
            }, status=status.HTTP_200_OK)
            
            
        else:
            return Response({
                "status": "success",
                "is_active": False,
                "message": "No active tour found"
            }, status=status.HTTP_200_OK)
            
            
    except Exception as e:
        return Response({
            "status": "failed",
            "message": str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)   
        
        
        
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def end_tour(request):
    try:
        
        if request.user.user_type != 'conductor':
            return Response({"status": "failed", "message": "Only conductors can end a tour"}, status=status.HTTP_403_FORBIDDEN)

        active_tour = Tour.objects.filter(conductor=request.user, is_active=True).first()
        
        if not active_tour:
            return Response({
                "status": "failed",
                "message": "No active tour found for this conductor."
            }, status=status.HTTP_404_NOT_FOUND)

        active_tour.is_active = False
        active_tour.save()

        return Response({
            "status": "success",
            "message": "Tour ended successfully."
        }, status=status.HTTP_200_OK)

    except Exception as e:
        return Response({
            "status": "failed",
            "message": str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def update_tour_location(request):
    try:
        if request.user.user_type != 'conductor':
            return Response({"status": "failed", "message": "Only conductors can update tour location"}, status=status.HTTP_403_FORBIDDEN)

        active_tour = Tour.objects.filter(conductor=request.user, is_active=True).first()
        
        if not active_tour:
            return Response({"status": "failed", "message": "No active tour found for this conductor"}, status=status.HTTP_404_NOT_FOUND)
        print(activate_tour)
        latitude = request.data.get('latitude')
        longitude = request.data.get('longitude')
        heading = request.data.get('heading')
        speed = request.data.get('speed')

        if latitude is None or longitude is None:
            return Response({"status": "failed", "message": "Latitude and longitude are required"}, status=status.HTTP_400_BAD_REQUEST)

        active_tour.latitude = latitude
        active_tour.longitude = longitude

        if heading is not None:
            active_tour.heading = heading

        if speed is not None:
            active_tour.speed = speed

        active_tour.save()

        return Response({"status": "success", "message": "Tour location updated successfully"}, status=status.HTTP_200_OK)

    except Exception as e:
        return Response({"status": "failed", "message": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_all_active_tours(request):
    try:
        # Retrieve all active tours
        active_tours = Tour.objects.filter(is_active=True)
        print(request.user)
        # If no active tours, return a message indicating no tours are available
        if not active_tours:
            return Response({"status": "success", "message": "No active tours available"}, status=status.HTTP_200_OK)
        
        # Serialize the active tours data
        serializer = TourSerializer(active_tours, many=True)
        # Return the response with a list of tours
        return Response({"status": "success", "data": serializer.data}, status=status.HTTP_200_OK)
    
    except Exception as e:
        return Response({"status": "failed", "message": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_tour_coordinates(request, tour_id):
    try:
        # Get the tour by ID, ensuring it exists
        tour = Tour.objects.get(id=tour_id)

        # Return the source and destination coordinates
        return Response({
            "source": {
                "latitude": tour.source_lat,
                "longitude": tour.source_lng
            },
            "destination": {
                "latitude": tour.destination_lat,
                "longitude": tour.destination_lng
            }
        }, status=200)
        
    except Tour.DoesNotExist:
        return Response({
            "status": "failed",
            "message": "Tour not found."
        }, status=404)
    except Exception as e:
        return Response({
            "status": "failed",
            "message": str(e)
        }, status=500)
        

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def set_tour_coordinates(request, tour_id):
    try:
        user = request.user

        if user.user_type != 'conductor':
            return Response({"status": "failed", "message": "Only conductors can update coordinates"}, status=status.HTTP_403_FORBIDDEN)
        
        tour = Tour.objects.filter(id=tour_id, conductor=user).first()
        
        if not tour:
            return Response({"status": "failed", "message": "Tour not found or user does not have permission to modify this tour"}, status=status.HTTP_404_NOT_FOUND)

        source_lat = request.data.get('source_lat')
        source_lng = request.data.get('source_lng')
        destination_lat = request.data.get('destination_lat')
        destination_lng = request.data.get('destination_lng')

        if source_lat is None or source_lng is None or destination_lat is None or destination_lng is None:
            return Response({"status": "failed", "message": "All coordinates (source and destination) are required"}, status=status.HTTP_400_BAD_REQUEST)
        
        tour.source_lat = source_lat
        tour.source_lng = source_lng
        tour.destination_lat = destination_lat
        tour.destination_lng = destination_lng
        tour.save()

        return Response({"status": "success", "message": "Coordinates updated successfully"}, status=status.HTTP_200_OK)
    
    except Exception as e:
        return Response({"status": "failed", "message": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)