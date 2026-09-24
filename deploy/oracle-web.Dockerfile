FROM node:20-alpine AS build

WORKDIR /app/edubridge-web

COPY edubridge-web/package.json edubridge-web/package-lock.json ./
RUN npm ci

COPY edubridge-web/ ./

ARG VITE_API_URL=/api
ENV VITE_API_URL=$VITE_API_URL

RUN npm run build

FROM node:20-alpine

WORKDIR /app

ENV NODE_ENV=production \
    PORT=8080 \
    TAQAT_API_ORIGIN=https://api.edubridge.win

COPY --from=build /app/edubridge-web/dist ./edubridge-web/dist
COPY deploy/taqat-web-server.mjs ./deploy/taqat-web-server.mjs

EXPOSE 8080

CMD ["node", "deploy/taqat-web-server.mjs"]
