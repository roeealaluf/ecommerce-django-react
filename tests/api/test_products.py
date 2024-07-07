import pytest

# @pytest.mark.django_db
# def test_product_created():
#   Product.objects.create
from rest_framework.reverse import reverse
from rest_framework.test import APIClient

from base.models import Product


def create_product():
  return Product.objects.create(
        name=" Product Name ",
        price=0,
        brand="Sample brand ",
        countInStock=0,
        category="Sample category",
        description=" ")

@pytest.mark.django_db
def test_product_creation():
  p = create_product()
  assert isinstance(p, Product) is True
  assert p.name == " Product Name "




# Api test  - Integration testing
@pytest.mark.django_db
def test_api_product_creation():
    client = APIClient()
    user = User.objects.create_user(username='testuser', password='123')
    client.force_authenticate(self.user)



    response = client.post("/api/products/create/")

    # data = response.data

    assert response.status_code == 200
