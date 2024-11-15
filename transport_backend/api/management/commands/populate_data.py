# your_app/management/commands/populate_data.py
from django.core.management.base import BaseCommand
from faker import Faker
from django.contrib.auth.models import Group, Permission
from api.models import CustomUser, Tour, Transaction
import random
import string

class CustomUserPopulator:
    @staticmethod
    def populate(fake, num_users=10):
        for _ in range(num_users):
            user_type = random.choice([CustomUser.TRAVELER, CustomUser.CONDUCTOR])
            name = fake.name()
            email = fake.unique.email()
            balance = fake.random_number(digits=5) / 100  # Random balance with 2 decimal places
            secret_key = ''.join(random.choices(string.ascii_letters + string.digits, k=128))  # Random 128 char string
            
            user = CustomUser.objects.create(
                username=fake.user_name(),
                email=email,
                name=name,
                balance=balance,
                secret_key=secret_key,
                user_type=user_type
            )

            groups = Group.objects.all()
            if groups.exists():
                user.groups.set(random.sample(list(groups), k=random.randint(1, 3)))

            permissions = Permission.objects.all()
            if permissions.exists():
                user.user_permissions.set(random.sample(list(permissions), k=random.randint(1, 3)))
                
            user.save()


class TourPopulator:
    @staticmethod
    def populate(fake, num_tours=5):
        for _ in range(num_tours):
            is_active = random.choice([True, False])  # Randomly active or inactive tour
            tour = Tour.objects.create(is_active=is_active)
            tour.save()


class TransactionPopulator:
    @staticmethod
    def populate(fake, num_transactions=20):
        travelers = CustomUser.objects.filter(user_type=CustomUser.TRAVELER)
        conductors = CustomUser.objects.filter(user_type=CustomUser.CONDUCTOR)
        tours = Tour.objects.all()

        for _ in range(num_transactions):
            if not travelers.exists() or not conductors.exists() or not tours.exists():
                print("Insufficient data to create transactions.")
                return
            
            traveler = random.choice(travelers)
            conductor = random.choice(conductors) if conductors.exists() else None
            tour = random.choice(tours)
            amount = fake.random_number(digits=5) / 100  # Random amount
            status = random.choice([Transaction.PENDING, Transaction.COMPLETED, Transaction.FAILED])
            
            transaction = Transaction.objects.create(
                traveler=traveler,
                conductor=conductor,
                amount=amount,
                status=status,
                tour=tour
            )
            transaction.save()


class Command(BaseCommand):
    help = 'Populate CustomUser, Tour, and Transaction models with random data for testing'

    def handle(self, *args, **kwargs):
        fake = Faker()

        self.stdout.write(self.style.SUCCESS('Populating CustomUser model...'))
        CustomUserPopulator.populate(fake)

        self.stdout.write(self.style.SUCCESS('Populating Tour model...'))
        TourPopulator.populate(fake)

        self.stdout.write(self.style.SUCCESS('Populating Transaction model...'))
        TransactionPopulator.populate(fake)

        self.stdout.write(self.style.SUCCESS('Successfully populated the models with random data'))
