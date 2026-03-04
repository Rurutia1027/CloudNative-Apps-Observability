FROM eclipse-temurin:17-jre-alpine

WORKDIR /app

# The Spring Boot jar should be built before docker build, e.g.:
# mvn -pl fraud -am clean package
ARG JAR_FILE=target/*.jar
COPY ${JAR_FILE} app.jar

ENV SPRING_PROFILES_ACTIVE=docker

EXPOSE 8081

ENTRYPOINT ["java","-jar","/app/app.jar"]

