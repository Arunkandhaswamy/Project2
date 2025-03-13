FROM nginx:alpine
COPY build /usr/share/nginx/html
EXPOSE 81
CMD ["nginx", "-g", "daemon off;"]
