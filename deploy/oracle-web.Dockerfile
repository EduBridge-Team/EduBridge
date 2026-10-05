FROM node:20-alpine AS build

WORKDIR /app/edubridge-web

COPY edubridge-web/package.json edubridge-web/package-lock.json ./
RUN npm ci

COPY edubridge-web/ ./

ARG VITE_API_URL=/api
ARG VITE_GOOGLE_CLIENT_ID=
ENV VITE_API_URL=$VITE_API_URL
ENV VITE_GOOGLE_CLIENT_ID=$VITE_GOOGLE_CLIENT_ID

RUN npm run build

FROM node:20-alpine

WORKDIR /app

ENV NODE_ENV=production \
    PORT=8080 \
    API_ORIGIN=https://api.edubridge.win

COPY --from=build /app/edubridge-web/dist ./edubridge-web/dist
COPY deploy/web-server.mjs deploy/static-encoding.mjs ./deploy/

EXPOSE 8080

CMD ["node", "deploy/web-server.mjs"]
