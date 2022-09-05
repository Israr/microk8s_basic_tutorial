FROM node:14-alpine
WORKDIR /app/
COPY index.js package.json /app/
RUN npm install
EXPOSE 3000
CMD [ "node" , "index.js"]
