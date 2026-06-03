FROM node:alpine

WORKDIR /app

COPY package-lock.json package.json /app/

RUN npm install

COPY . .

EXPOSE 3000

CMD [ "npm", "start" ]