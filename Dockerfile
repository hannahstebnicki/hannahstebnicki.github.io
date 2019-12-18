FROM node:11-alpine

ENV HOME /app
WORKDIR $HOME
ADD . $HOME/

# Build production runtime
RUN npm install npm@latest -g
RUN npm install
RUN npm run build

CMD npm start