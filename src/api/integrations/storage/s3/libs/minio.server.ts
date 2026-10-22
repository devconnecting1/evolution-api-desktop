import {
  CreateBucketCommand,
  DeleteObjectCommand,
  GetObjectCommand,
  HeadBucketCommand,
  PutBucketPolicyCommand,
  PutObjectCommand,
  S3Client,
} from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { ConfigService, S3 } from '@config/env.config';
import { Logger } from '@config/logger.config';
import { BadRequestException } from '@exceptions';
import { posix } from 'path';
import { Readable, Transform } from 'stream';

const logger = new Logger('S3 Service');

const BUCKET = new ConfigService().get<S3>('S3');

interface Metadata extends Record<string, string> {
  'Content-Type': string;
}

const s3Client = (() => {
  if (BUCKET?.ENABLE) {
    const protocol = BUCKET.USE_SSL ? 'https' : 'http';
    const endpoint = BUCKET.PORT
      ? `${protocol}://${BUCKET.ENDPOINT}:${BUCKET.PORT}`
      : `${protocol}://${BUCKET.ENDPOINT}`;

    return new S3Client({
      endpoint,
      region: BUCKET.REGION || 'us-east-1',
      credentials: {
        accessKeyId: BUCKET.ACCESS_KEY,
        secretAccessKey: BUCKET.SECRET_KEY,
      },
      forcePathStyle: true,
    });
  }
})();

const bucketName = BUCKET.BUCKET_NAME;

const bucketExists = async () => {
  if (s3Client) {
    try {
      await s3Client.send(new HeadBucketCommand({ Bucket: bucketName }));
      return true;
    } catch {
      return false;
    }
  }
};

const setBucketPolicy = async () => {
  if (s3Client) {
    const policy = {
      Version: '2012-10-17',
      Statement: [
        {
          Effect: 'Allow',
          Principal: '*',
          Action: ['s3:GetObject'],
          Resource: [`arn:aws:s3:::${bucketName}/*`],
        },
      ],
    };
    await s3Client.send(
      new PutBucketPolicyCommand({
        Bucket: bucketName,
        Policy: JSON.stringify(policy),
      }),
    );
  }
};

const createBucket = async () => {
  if (s3Client) {
    try {
      const exists = await bucketExists();
      if (!exists) {
        await s3Client.send(new CreateBucketCommand({ Bucket: bucketName }));
      }
      if (!BUCKET.SKIP_POLICY) {
        await setBucketPolicy();
      }
      logger.info(`S3 Bucket ${bucketName} - ON`);
      return true;
    } catch (error) {
      logger.error('S3 ERROR:');
      logger.error(error);
      return false;
    }
  }
};

createBucket();

const putObject = async (objectName: string, file: Buffer | Transform | Readable, size: number, metadata: Metadata) => {
  if (s3Client) {
    const { 'Content-Type': contentType, ...customMetadata } = metadata;
    return await s3Client.send(
      new PutObjectCommand({
        Bucket: bucketName,
        Key: objectName,
        Body: file,
        ContentLength: size,
        ContentType: contentType,
        Metadata: { ...customMetadata, 'custom-header-application': 'evolution-api' },
      }),
    );
  }
};

const uploadFile = async (fileName: string, file: Buffer | Transform | Readable, size: number, metadata: Metadata) => {
  if (s3Client) {
    const objectName = posix.join('evolution-api', fileName);
    try {
      return await putObject(objectName, file, size, metadata);
    } catch (error) {
      logger.error(error);
      return error;
    }
  }
};

const getObjectUrl = async (fileName: string, expiry?: number) => {
  if (s3Client) {
    try {
      const objectName = posix.join('evolution-api', fileName);
      const expiresIn = Math.min(expiry || 7 * 24 * 60 * 60, 7 * 24 * 60 * 60);

      return await getSignedUrl(s3Client, new GetObjectCommand({ Bucket: bucketName, Key: objectName }), { expiresIn });
    } catch (error) {
      throw new BadRequestException((error as Error)?.message);
    }
  }
};

const uploadTempFile = async (
  folder: string,
  fileName: string,
  file: Buffer | Transform | Readable,
  size: number,
  metadata: Metadata,
) => {
  if (s3Client) {
    const objectName = posix.join(folder, fileName);
    try {
      return await putObject(objectName, file, size, metadata);
    } catch (error) {
      logger.error(error);
      return error;
    }
  }
};

const deleteFile = async (folder: string, fileName: string) => {
  if (s3Client) {
    const objectName = posix.join(folder, fileName);
    try {
      return await s3Client.send(new DeleteObjectCommand({ Bucket: bucketName, Key: objectName }));
    } catch (error) {
      logger.error(error);
      return error;
    }
  }
};

export { BUCKET, deleteFile, getObjectUrl, uploadFile, uploadTempFile };
