FROM alpine:latest

RUN echo "Hola Mundo desde Alpine Linux" > /app/hola.txt

CMD ["cat", "/app/hola.txt"]