from rest_framework import serializers
from .models import CustomUser, Transaction,Tour
from cryptography.hazmat.primitives import serialization

# for user details
class CustomUserSerializer(serializers.ModelSerializer):
    total_trips = serializers.SerializerMethodField()

    class Meta:
        model = CustomUser
        fields = ['name', 'email', 'balance', 'total_trips']

    def get_total_trips(self, obj):
        if obj.is_conductor:
            return obj.conductor_tour.count()
        elif obj.is_traveler:
            return obj.transactions.count()
        return 0

        


from rest_framework import serializers
from .models import Transaction

# for transaction history
class TransactionSerializer(serializers.ModelSerializer):
    traveler_name = serializers.CharField(source='traveler.name', read_only=True)
    conductor_name = serializers.CharField(source='conductor.name', read_only=True)

    class Meta:
        model = Transaction
        fields = ['id', 'amount', 'transaction_date', 'status', 'traveler_name', 'conductor_name', 'tour_id']

#  to update secret key
class SecretKeyUpdateSerializer(serializers.Serializer):
    secret_key = serializers.CharField()
    
    
    def update(self, instance, validated_data):
        instance.secret_key = validated_data.get('secret_key', instance.secret_key)
        instance.save()
        return instance
    
    
#  validation of qr code goes here:::

class QRCodeDataSerializer(serializers.Serializer):
    created_date = serializers.DateTimeField()
    name = serializers.CharField(max_length=100)
    amount = serializers.DecimalField(max_digits=10, decimal_places=2)
    user_name = serializers.CharField(max_length=150)
  


#  to activate the tour :
class TourSerializer(serializers.ModelSerializer):
    conductor_name = serializers.CharField(source='conductor.name', read_only=True)

    class Meta:
        model = Tour
        fields = ['id', 'is_active','latitude', 'longitude', 'heading', 'speed', 'conductor_name','source_lat','source_lng','destination_lat','destination_lng','veh_num']

# Load the public key from PEM format
def load_public_key(pem_data):
    return serialization.load_pem_public_key(pem_data.encode())
