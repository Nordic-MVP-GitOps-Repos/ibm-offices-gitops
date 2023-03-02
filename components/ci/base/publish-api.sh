set -x 

export OFFICE_SERVICE_BASE_URL=https://secure-route-ibmoffices.apps.oc31okmp.eastus.aroapp.io
             
export TARGET_URL=$OFFICE_SERVICE_BASE_URL/offices

# Fetch openapi description of the ibmoffices service
curl -k -s $OFFICE_SERVICE_BASE_URL/q/openapi > openapi.yaml

# Set description, version and title of the api
yq -i '.info.description = "Git commit is 1234 "' openapi.yaml
yq -i '.info.version = "1.0.0"' openapi.yaml
yq -i '.info.title = "ibm-offices-1234"' openapi.yaml

# Add target-url gateway property
yq -i '.x-ibm-configuration.properties += {"target-url": {"value": strenv(TARGET_URL)}}' openapi.yaml

apic validate openapi.yaml

# Create a draft API on the APIC server
created_api=$(apic draft-apis:create --api_type rest --gateway_type datapower-api-gateway ./openapi.yaml)
export created_api_name=${created_api%%[[:space:]]*}

#echo "Created draft api: $created_api_name"

# Add references to the created draft apis to the product
# See https://www.ibm.com/docs/en/api-connect/10.0.5.x_lts?topic=file-referencing-apis-your-product

# TODO: remove : in first argument for correct reference.

export apim_api_name=$(echo $created_api_name | sed 's/://')

export PRODUCT_NAME="${apim_api_name}-Product"

# Create a product yaml file on the local filesystem
apic create:product --name $PRODUCT_NAME --title $PRODUCT_NAME --gateway-type datapower-api-gateway  --filename product.yaml 

cat product.yaml

yq -i '.apis += {strenv(apim_api_name): {"name":strenv(created_api_name)}}' product.yaml

cat product.yaml

apic validate product.yaml

# Create the draft product on the APIC server
apic draft-products:create product.yaml

#apic draft-products:publish product.yaml