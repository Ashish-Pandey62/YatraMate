from django.db import models
from django.contrib.auth.models import AbstractUser

from django.db import models
from django.contrib.auth.models import AbstractUser, Group, Permission

class CustomUser(AbstractUser):
    TRAVELER = 'traveler'
    CONDUCTOR = 'conductor'

    USER_TYPE_CHOICES = [
        (TRAVELER, 'Traveler'),
        (CONDUCTOR, 'Conductor'),
    ]
    
    

    user_type = models.CharField(max_length=10, choices=USER_TYPE_CHOICES)
    email = models.EmailField(unique=True)  
    name = models.CharField(max_length=100, null=False, blank=False)
    balance = models.DecimalField(max_digits=10, decimal_places=2, default=500)
    secret_key = models.TextField()

    groups = models.ManyToManyField(
        Group,
        related_name="customuser_groups",  
        blank=True
    )
    user_permissions = models.ManyToManyField(
        Permission,
        related_name="customuser_permissions",  
        blank=True
    )
    
    def __str__(self):
        return f"{self.username} ({self.user_type})"

    @property
    def is_traveler(self):
        return self.user_type == self.TRAVELER

    @property
    def is_conductor(self):
        return self.user_type == self.CONDUCTOR




#  Tour  Model would be implemented later 
class Tour(models.Model):
    is_active = models.BooleanField(default=False)
    latitude = models.DecimalField(max_digits=9, decimal_places=6, default=27)
    longitude = models.DecimalField(max_digits=9, decimal_places=6, default=27)
    heading = models.DecimalField(max_digits=9, decimal_places=6, default=0.0)
    speed = models.DecimalField(max_digits=9, decimal_places=6, default=0.0)
    source = models.CharField(max_length=255, null=False, blank=False)
    destination = models.CharField(max_length=255, null=False, blank=False)

    conductor = models.ForeignKey(
        CustomUser,
        on_delete=models.CASCADE,
        limit_choices_to={'user_type': 'conductor'},
        related_name='conductor_tour',
        null=True
    )

    def __str__(self):
        return f"Tour is {'active' if self.is_active else 'inactive'} at {self.latitude}, {self.longitude} by {self.conductor}"

    
    # def __str__(self):
        # return f"{self.source} to {self.destination}"
    
    
class Transaction(models.Model):
    PENDING = 'pending'
    COMPLETED = 'completed'
    FAILED = 'failed'
    
    STATUS_CHOICES = [
        (PENDING, 'Pending'),
        (COMPLETED, 'Completed'),
        (FAILED, 'Failed')
    ]

    traveler = models.ForeignKey(
        CustomUser, 
        on_delete=models.CASCADE, 
        limit_choices_to={'user_type': 'traveler'},
        related_name='transactions'
    )
    conductor = models.ForeignKey(
        CustomUser,
        on_delete=models.CASCADE,
        limit_choices_to={'user_type': 'conductor'},
        related_name='conducted_transactions',
        null=True
    )
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    transaction_date = models.DateTimeField(auto_now_add=True)
    status = models.CharField(max_length=10, choices=STATUS_CHOICES, default=PENDING)
    tour = models.ForeignKey(Tour, on_delete=models.CASCADE, related_name='transactions',null = True)
    

    def __str__(self):
        return f"Transaction of {self.amount} by {self.traveler.username}"

    class Meta:
        ordering = ['-transaction_date']
        

# table to store the jwt tokens which contains user info:

class TokenRecord(models.Model):
    user = models.ForeignKey(CustomUser,on_delete=models.CASCADE)
    token = models.TextField()
    expires_at = models.DateTimeField()

    def __str__(self):
        return f"Token for {self.user} expires at {self.expires_at}"

