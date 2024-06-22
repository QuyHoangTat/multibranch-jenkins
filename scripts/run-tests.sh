#!/bin/bash

# Chạy tests cho service assets-nginx (không có tests)
echo "No tests for assets-nginx"

# Chạy tests cho service cart-java
echo "Running tests for cart-java"
cd src/cart
mvn test
cd -

# Chạy tests cho service catalog-go
echo "Running tests for catalog-go"
cd src/catalog
go test ./...
cd -

# Chạy tests cho service checkout-node
echo "Running tests for checkout-node"
cd src/checkout
npm test
cd -

# Chạy tests cho service orders-java
echo "Running tests for orders-java"
cd src/orders
mvn test
cd -

# Chạy tests cho service ui-java
echo "Running tests for ui-java"
cd src/ui
mvn test
cd -
