from django.contrib import admin
from api.models import CustomUser,Transaction,Tour,TokenRecord

# Register your models here.
admin.site.register(CustomUser)
admin.site.register(Tour)
admin.site.register(Transaction)
admin.site.register(TokenRecord)
