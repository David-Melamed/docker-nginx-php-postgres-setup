# Start from the Nginx official image
FROM nginx:latest

# Copy your custom index.html into the image
COPY index.html /usr/share/nginx/html/index.html

# Expose port 80 to the outside world
EXPOSE 80

# Command to run when the container starts
CMD ["nginx", "-g", "daemon off;"]