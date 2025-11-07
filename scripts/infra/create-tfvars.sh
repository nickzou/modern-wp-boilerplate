#!/bin/bash
# env-to-tfvars.sh - Convert .env TF_ variables to terraform.tfvars

# Path to your .env file
ENV_FILE=".env"

# Path to the output terraform.tfvars file
TFVARS_FILE="infrastructure/terraform.tfvars"

# Check if .env file exists
if [ ! -f "$ENV_FILE" ]; then
    echo "Error: $ENV_FILE file not found."
    exit 1
fi

# Clear or create terraform.tfvars file
> "$TFVARS_FILE"

echo "# Generated from $ENV_FILE on $(date)" > "$TFVARS_FILE"
echo "# Contains variables prefixed with TF_ in .env file" >> "$TFVARS_FILE"
echo "" >> "$TFVARS_FILE"

# Process each line in the .env file
while IFS= read -r line || [[ -n "$line" ]]; do
    # Skip comments and empty lines
    [[ $line = \#* ]] && continue
    [[ -z $line ]] && continue
    
    # Check if the line starts with TF_
    if [[ $line =~ ^TF_ ]]; then
        # Extract the key and value
        key=$(echo "$line" | cut -d '=' -f1)
        value=$(echo "$line" | cut -d '=' -f2-)
        
        # Remove TF_ prefix and convert to lowercase
        key_cleaned=$(echo "$key" | sed 's/^TF_//' | tr '[:upper:]' '[:lower:]')
        
        # Determine if the value needs quotes (strings do, numbers don't)
        if [[ $value =~ ^[0-9]+$ ]]; then
            # It's a number, no quotes needed
            echo "$key_cleaned = $value" >> "$TFVARS_FILE"
        elif [[ $value =~ ^true$|^false$ ]]; then
            # It's a boolean, no quotes needed
            echo "$key_cleaned = $value" >> "$TFVARS_FILE"
        elif [[ $value =~ ^\[.*\]$ ]]; then
            # It's a list, keep as is
            echo "$key_cleaned = $value" >> "$TFVARS_FILE"
        elif [[ $value =~ ^\{.*\}$ ]]; then
            # It's a map/object, keep as is
            echo "$key_cleaned = $value" >> "$TFVARS_FILE"
        else
            # It's a string, add quotes
            echo "$key_cleaned = \"$value\"" >> "$TFVARS_FILE"
        fi
    fi
done < "$ENV_FILE"

echo "Setup complete. Created $TFVARS_FILE with TF_ variables from $ENV_FILE."

