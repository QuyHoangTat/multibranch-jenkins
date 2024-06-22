#!/bin/bash

# Cài đặt thư viện cho service assets-nginx (không cần cài đặt thư viện)
echo "No libraries to install for assets-nginx"

# Cài đặt thư viện cho service cart-java
echo "Installing libraries for cart-java"
cd src/cart
mvn install
cd -

# Cài đặt thư viện cho service catalog-go
echo "Installing libraries for catalog-go"
cd src/catalog
go get ./...
cd -

# Cài đặt thư viện cho service checkout-node
echo "Installing libraries for checkout-node"
cd src/checkout
npm install
cd -

# Cài đặt thư viện cho service orders-java
echo "Installing libraries for orders-java"
cd src/orders
mvn install
cd -

# Cài đặt thư viện cho service ui-java
echo "Installing libraries for ui-java"
cd src/ui
mvn install
cd -
