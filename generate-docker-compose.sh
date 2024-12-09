#!/bin/bash

output_file="docker-compose.yml"
echo "version: '3.8'" > $output_file
echo "services:" >> $output_file

for container in $(docker ps -q); do
    container_name=$(docker inspect $container | jq -r '.[0].Name' | cut -d'/' -f2)
    image_name=$(docker inspect $container | jq -r '.[0].Config.Image')
    ports=$(docker inspect $container | jq -r '.[0].HostConfig.PortBindings | to_entries[] | "- \(.value[0].HostPort):\(.key | split("/")[0])"')
    volumes=$(docker inspect $container | jq -r '.[0].Mounts[] | "- \(.Source):\(.Destination)"')
    env_vars=$(docker inspect $container | jq -r '.[0].Config.Env[] | "- \(. )"')

    echo "  $container_name:" >> $output_file
    echo "    image: $image_name" >> $output_file
    echo "    container_name: $container_name" >> $output_file

    if [[ ! -z "$ports" ]]; then
        echo "    ports:" >> $output_file
        echo "$ports" | sed 's/^/      /' >> $output_file
    fi

    if [[ ! -z "$volumes" ]]; then
        echo "    volumes:" >> $output_file
        echo "$volumes" | sed 's/^/      /' >> $output_file
    fi

    if [[ ! -z "$env_vars" ]]; then
        echo "    environment:" >> $output_file
        echo "$env_vars" | sed 's/^/      /' >> $output_file
    fi

    echo "    restart: unless-stopped" >> $output_file
done

echo "Generated $output_file successfully."
