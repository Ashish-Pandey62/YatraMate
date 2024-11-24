from django.urls import path
from .views import UserDetailsView,TransactionHistoryView,UpdateSecretKeyView,validate_qr_code,check_active_tour,activate_tour,end_tour,update_tour_location,get_all_active_tours
from . import views

urlpatterns = [
    path('user-details/', UserDetailsView.as_view(), name='user-details'),
    path('transaction-history/', TransactionHistoryView.as_view(), name='transaction-history'),
    path('update-secret-key/', UpdateSecretKeyView.as_view(), name='update-secret-key'),
    path('validate-qr/', views.validate_qr_code, name='validate_qr_code'),
    path('activate-tour/', views.activate_tour, name='activate_tour'),    
    path('active-tour/', views.check_active_tour, name='active_tour'),  
    path('end-tour/', views.end_tour, name='end_tour'),  
    path('update-location/', views.update_tour_location, name='update_location'),
    path('all-active-tour/', views.get_all_active_tours, name='active_tour'),
    path('tour/<int:tour_id>/source-destination-coords/', views.get_tour_coordinates, name='tour-source-destination_coords'),
    path('tour/<int:tour_id>/set-coordinates/', views.set_tour_coordinates, name='set_tour_coordinates'),
    path('traffic-flow/', views.traffic_flow, name='traffic_flow'),

]


