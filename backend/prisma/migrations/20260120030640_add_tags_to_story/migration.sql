/*
  Warnings:

  - You are about to drop the column `emotion` on the `Story` table. All the data in the column will be lost.

*/
-- AlterTable
ALTER TABLE "Story" DROP COLUMN "emotion";

-- DropEnum
DROP TYPE "Emotion";

-- CreateTable
CREATE TABLE "Tag" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,

    CONSTRAINT "Tag_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "_StoryToTag" (
    "A" TEXT NOT NULL,
    "B" TEXT NOT NULL,

    CONSTRAINT "_StoryToTag_AB_pkey" PRIMARY KEY ("A","B")
);

-- CreateIndex
CREATE UNIQUE INDEX "Tag_name_key" ON "Tag"("name");

-- CreateIndex
CREATE INDEX "_StoryToTag_B_index" ON "_StoryToTag"("B");

-- AddForeignKey
ALTER TABLE "_StoryToTag" ADD CONSTRAINT "_StoryToTag_A_fkey" FOREIGN KEY ("A") REFERENCES "Story"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "_StoryToTag" ADD CONSTRAINT "_StoryToTag_B_fkey" FOREIGN KEY ("B") REFERENCES "Tag"("id") ON DELETE CASCADE ON UPDATE CASCADE;
