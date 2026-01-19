import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
    await prisma.advice.deleteMany();

    const advicesData = [
        { content: "advice 1", author: "author 1" },
        { content: "advice 2", author: "author 2" },
        { content: "advice 3", author: "author 3" },
        { content: "advice 4", author: "author 4" }
    ]

    for (const item of advicesData) {
        await prisma.advice.create({
            data: item,
        });
    }
}

main()
    .catch((e) => {
        console.error(e);
        process.exit(1);
    })
    .finally(async() => {
        await prisma.$disconnect();
    });