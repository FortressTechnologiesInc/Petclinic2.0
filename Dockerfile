# Use the official Tomcat image as the base image
FROM tomcat:9.0

# Copy the petshop.war file from the host to the Tomcat webapps directory
COPY target/petshop.war /usr/local/tomcat/webapps/
#COPY ../target/petshop.war /usr/local/tomcat/webapps/

# Expose port 8080 (Tomcat's default port)
EXPOSE 8080
