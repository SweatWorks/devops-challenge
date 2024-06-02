import { RequestHandler } from 'express'
import db, { orm, schema } from '@dc/database'
import { getSignedUrl } from '@aws-sdk/s3-request-presigner'
import {
  PutObjectCommand,
  GetObjectCommand,
  S3Client
} from '@aws-sdk/client-s3'

const s3Client = new S3Client({ region: process.env.AWS_REGION })

export const createPhoto: RequestHandler = async function (req, res, next) {
  try {
    const { originalName } = req.body

    const [photo] = await db
      .insert(schema.photos)
      // This is for testing, needs to point to the correct key when the key changes after proccessing by the lambda "resized/${originalName}.webp ??"
      // and the bucketName was missing
      .values({ originalName, bucketName: process.env.PHOTOS_BUCKET, key: `uploads/${originalName}`})
      .returning()

    const command = new PutObjectCommand({
      Bucket: process.env.PHOTOS_BUCKET,
      Key: `uploads/${photo.id}`
    })

    const signedUrl = await getSignedUrl(s3Client, command, { expiresIn: 3600 })

    return res.status(200).json({
      ...photo,
      signedUrl
    })
  } catch (error) {
    next(error)
  }
}

export const getPhotos: RequestHandler = async function (req, res, next) {
  try {
    const photos = await db.query.photos.findMany()

    const signedUrlPromises = photos.map((photo) => {
      const command = new GetObjectCommand({
        Bucket: photo.bucketName || '',
        Key: photo.key || ''
      })

      return getSignedUrl(s3Client, command, { expiresIn: 3600 })
    })

    const signedS3Urls = await Promise.all(signedUrlPromises)

    return res.status(200).json(
      photos.map((photo, index) => ({
        ...photo,
        signedUrl: signedS3Urls[index]
      }))
    )
  } catch (error) {
    next(error)
  }
}

export const getPhoto: RequestHandler = async function (req, res, next) {
  try {
    const photo = await db.query.photos.findFirst({
      where: orm.eq(schema.photos.id, req.params.id)
    })

    if (!photo) throw new Error('Photo not found')

    const command = new GetObjectCommand({
      Bucket: photo.bucketName || '',
      Key: photo.key || ''
    })

    const signedUrl = await getSignedUrl(s3Client, command, { expiresIn: 3600 })

    return res.status(200).json({
      ...photo,
      signedUrl
    })
  } catch (error) {
    next(error)
  }
}

export const deletePhoto: RequestHandler = async function (req, res, next) {
  try {
    const { id } = req.params

    const [photo] = await db
      .delete(schema.photos)
      .where(orm.eq(schema.photos.id, id))
      .returning()

    return res.status(200).json(photo)
  } catch (error) {
    next(error)
  }
}
