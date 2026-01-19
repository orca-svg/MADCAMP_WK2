FROM node:18-slim

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .

RUN DATABASE_URL="postgresql://johndoe:randompassword@localhost:5432/mydb" npx prisma generate

RUN npm run build

CMD ["node", "dist/src/main"]
