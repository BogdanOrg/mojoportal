using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;
using System.Linq;
using System.Text;
using System.Xml;
using log4net;
using mojoPortal.FileSystem;

namespace mojoPortal.Web;

/// <summary>
/// A helper class for manipulating images
/// </summary>
public sealed class ImageHelper
{
	private static readonly ILog log = LogManager.GetLogger(typeof(ImageHelper));

	#region Enums

	public enum ResizeOption
	{
		NoResize,
		FixedWidthHeight,
		MaintainAspectWidth,
		MaintainAspectHeight
	}

	#endregion

	#region Public Static Methods

	public static void SetMetadata(string key, string data, XmlDocument xmlDoc)
	{
		if ((xmlDoc != null) && (key != null) && (data != null))
		{
			XmlNode targetNode = xmlDoc.SelectSingleNode("/Metadata/@" + key);
			if (targetNode == null)
			{
				XmlAttribute newAttribute = xmlDoc.CreateAttribute(key);
				newAttribute.Value = data;
				xmlDoc.DocumentElement.Attributes.Append(newAttribute);
			}
			else
			{
				targetNode.Value = data;
			}
		}
	}

	public static string GetMetadata(string key, XmlDocument xmlDoc)
	{
		if ((xmlDoc != null) && (key != null))
		{
			XmlNode targetNode = xmlDoc.SelectSingleNode("/Metadata/@" + key);
			if (targetNode == null)
			{
				return null;
			}
			else
			{
				return targetNode.Value;
			}
		}
		else
		{
			return string.Empty;
		}
	}

	public static string ConvertByteArrayToString(byte[] array)
	{
		if (array != null)
		{
			var sb = new StringBuilder();
			for (int i = 0; i < array.Length - 1; i++) sb.Append((char)array[i]);
			return sb.ToString();
		}
		else
		{
			return string.Empty;
		}
	}

	public static byte ConvertByteArrayToByte(byte[] array)
	{
		if (array != null)
		{
			return array[0];
		}

		return byte.MinValue;
	}

	public static short ConvertByteArrayToShort(byte[] array)
	{
		short val = 0;
		if (array != null)
		{
			for (int i = 0; i < array.Length; i++) val += (short)(array[i] * Math.Pow(2, (i * 8)));
		}

		return val;
	}

	public static long ConvertByteArrayToLong(byte[] array)
	{
		long val = 0;
		if (array != null)
		{
			for (int i = 0; i < array.Length; i++) val += (array[i] * (long)Math.Pow(2, (i * 8)));

		}
		return val;
	}

	public static string ConvertByteArrayToRational(byte[] array)
	{
		if (array != null)
		{
			int val1 = 0;
			int val2 = 0;

			for (int i = 0; i < 4; i++) val1 += (array[i] * (int)Math.Pow(2, (i * 8)));
			for (int i = 4; i < 8; i++) val2 += (array[i] * (int)Math.Pow(2, ((i - 4) * 8)));
			if (val2 == 1)
			{
				return val1.ToString();
			}
			else
			{
				return ((double)val1 / (double)val2).ToString();
			}
		}

		return null;
	}

	public static string ConvertByteArrayToSRational(byte[] array)
	{
		if (array != null)
		{
			int val1 = 0;
			int val2 = 0;

			for (int i = 0; i < 4; i++) val1 += (array[i] * (int)Math.Pow(2, (i * 8)));
			for (int i = 4; i < 8; i++) val2 += (array[i] * (int)Math.Pow(2, ((i - 4) * 8)));
			if (val2 == 1)
			{
				return val1.ToString();
			}
			else
			{
				return ((double)val1 / (double)val2).ToString();
			}
		}

		return null;
	}

	public static double ExifGpsToDouble(PropertyItem propItemRef, PropertyItem propItem)
	{
		if (propItemRef == null) { return 0; }
		if (propItem == null) { return 0; }

		double degreesNumerator = BitConverter.ToUInt32(propItem.Value, 0);
		double degreesDenominator = BitConverter.ToUInt32(propItem.Value, 4);
		double degrees = degreesNumerator / (double)degreesDenominator;

		double minutesNumerator = BitConverter.ToUInt32(propItem.Value, 8);
		double minutesDenominator = BitConverter.ToUInt32(propItem.Value, 12);
		double minutes = minutesNumerator / (double)minutesDenominator;

		double secondsNumerator = BitConverter.ToUInt32(propItem.Value, 16);
		double secondsDenominator = BitConverter.ToUInt32(propItem.Value, 20);
		double seconds = secondsNumerator / (double)secondsDenominator;


		double coordinate = degrees + (minutes / 60d) + (seconds / 3600d);
		string gpsRef = Encoding.ASCII.GetString(new byte[1] { propItemRef.Value[0] }); //N, S, E, or W
		if (gpsRef == "S" || gpsRef == "W")
		{
			coordinate *= -1;
		}

		return coordinate;
	}

	public static Bitmap RotateFlip(Bitmap original, string flip, string rotate)
	{
		if ((original != null) && (flip != null) && (rotate != null))
		{
			RotateFlipType rotateFlipType = RotateFlipType.RotateNoneFlipNone;

			if (flip == "None" && rotate == "180")
			{
				rotateFlipType = RotateFlipType.Rotate180FlipNone;
			}
			else if (flip == "X" && rotate == "180")
			{
				rotateFlipType = RotateFlipType.Rotate180FlipX;
			}
			else if (flip == "XY" && rotate == "180")
			{
				rotateFlipType = RotateFlipType.Rotate180FlipXY;
			}
			else if (flip == "Y" && rotate == "180")
			{
				rotateFlipType = RotateFlipType.Rotate180FlipY;
			}
			else if (flip == "None" && rotate == "270")
			{
				rotateFlipType = RotateFlipType.Rotate270FlipNone;
			}
			else if (flip == "X" && rotate == "270")
			{
				rotateFlipType = RotateFlipType.Rotate270FlipX;
			}
			else if (flip == "XY" && rotate == "270")
			{
				rotateFlipType = RotateFlipType.Rotate270FlipXY;
			}
			else if (flip == "Y" && rotate == "270")
			{
				rotateFlipType = RotateFlipType.Rotate270FlipY;
			}
			else if (flip == "None" && rotate == "90")
			{
				rotateFlipType = RotateFlipType.Rotate90FlipNone;
			}
			else if (flip == "X" && rotate == "90")
			{
				rotateFlipType = RotateFlipType.Rotate90FlipX;
			}
			else if (flip == "XY" && rotate == "90")
			{
				rotateFlipType = RotateFlipType.Rotate90FlipXY;
			}
			else if (flip == "Y" && rotate == "90")
			{
				rotateFlipType = RotateFlipType.Rotate90FlipY;
			}
			else if (flip == "None" && rotate == "None")
			{
				rotateFlipType = RotateFlipType.RotateNoneFlipNone;
			}
			else if (flip == "X" && rotate == "None")
			{
				rotateFlipType = RotateFlipType.RotateNoneFlipX;
			}
			else if (flip == "XY" && rotate == "None")
			{
				rotateFlipType = RotateFlipType.RotateNoneFlipXY;
			}
			else if (flip == "Y" && rotate == "None")
			{
				rotateFlipType = RotateFlipType.RotateNoneFlipY;
			}

			original.RotateFlip(rotateFlipType);
		}

		return original;
	}

	public static ImageCodecInfo GetEncoderInfo(string mimeType)
	{
		// Get image codecs for all image formats
		ImageCodecInfo[] codecs = ImageCodecInfo.GetImageEncoders();

		// Find the correct image codec
		for (int i = 0; i < codecs.Length; i++)
		{
			if (codecs[i].MimeType == mimeType)
			{
				return codecs[i];
			}
		}

		return null;
	}

	public static double GetScaleFactor(int inputWidth, int inputHeight, int maxWidth, int maxHeight)
	{
		double scaleFactor = 0;

		if (inputWidth == 0) { return scaleFactor; }
		if (inputHeight == 0) { return scaleFactor; }
		if (maxHeight == 0) { return scaleFactor; }

		double aspectRatio = (double)inputWidth / (double)inputHeight;
		double boxRatio = (double)maxWidth / (double)maxHeight;

		if (boxRatio > aspectRatio)
		{
			//Use height, since that is the most restrictive dimension of box.
			scaleFactor = (double)maxHeight / (double)inputHeight;
		}
		else
		{
			scaleFactor = (double)maxWidth / (double)inputWidth;
		}

		return scaleFactor;
	}

	/// <summary>
	/// http://weblogs.asp.net/gunnarpeipman/archive/2009/04/02/resizing-images-without-loss-of-quality.aspx
	/// http://nathanaeljones.com/11191_20_Image_Resizing_Pitfalls
	/// </summary>
	/// <param name="imageFilePath"></param>
	/// <param name="mimeType"></param>
	/// <param name="maxWidth"></param>
	/// <param name="maxHeight"></param>
	public static void ResizeImage(string imageFilePath, string mimeType, int maxWidth, int maxHeight, Color backgroundColor)
	{
		bool allowEnlargement = false;
		ResizeImage(imageFilePath, mimeType, maxWidth, maxHeight, allowEnlargement, backgroundColor);

	}

	/// <summary>
	/// http://weblogs.asp.net/gunnarpeipman/archive/2009/04/02/resizing-images-without-loss-of-quality.aspx
	/// http://nathanaeljones.com/11191_20_Image_Resizing_Pitfalls
	/// </summary>
	/// <param name="imageFilePath"></param>
	/// <param name="mimeType"></param>
	/// <param name="maxWidth"></param>
	/// <param name="maxHeight"></param>
	public static void ResizeImage(string imageFilePath, string mimeType, int maxWidth, int maxHeight, bool allowEnlargement, Color backgroundColor)
	{
		var fileSystem = FileSystemHelper.LoadFileSystem();

		if (fileSystem is null || !fileSystem.FileExists(imageFilePath))
		{
			return;
		}

		double scaleFactor = 0;
		string tmpFilePath = imageFilePath + ".tmp" + Path.GetExtension(imageFilePath);
		bool imageNeedsResizing = true;

		try
		{
			//we can't overwrite the same file we have open so first make a temp copy

			//File.Copy(imageFilePath, tmpFilePath, true);
			fileSystem.CopyFile(imageFilePath, tmpFilePath, true);

			// this will only work with disk file needed to change to use FromStream
			//using (Image fullsizeImage = Image.FromFile(tmpFilePath))
			using (Stream tmpFileStream = fileSystem.GetAsStream(tmpFilePath))
			{
				using (Image fullsizeImage = Image.FromStream(tmpFileStream))
				{
					scaleFactor = GetScaleFactor(fullsizeImage.Width, fullsizeImage.Height, maxWidth, maxHeight);

					if (!allowEnlargement)
					{
						// don't need to resize since image is smaller than max
						if (scaleFactor > 1) { imageNeedsResizing = false; }
						if (scaleFactor == 0) { imageNeedsResizing = false; }
					}

					if (imageNeedsResizing)
					{
						int newWidth = (int)(fullsizeImage.Width * scaleFactor);
						int newHeight = (int)(fullsizeImage.Height * scaleFactor);

						using (Bitmap resizedBitmap = new Bitmap(newWidth, newHeight, PixelFormat.Format24bppRgb))
						{
							using (Graphics graphics = Graphics.FromImage(resizedBitmap))
							{
								//graphics.CompositingQuality = CompositingQuality.HighSpeed;
								//graphics.SmoothingMode = SmoothingMode.HighQuality;
								graphics.InterpolationMode = InterpolationMode.HighQualityBicubic;
								//graphics.PixelOffsetMode = PixelOffsetMode.HighSpeed;
								//graphics.Clear(Color.White);
								if (backgroundColor != null) { graphics.Clear(backgroundColor); }

								//graphics.ScaleTransform((float)scaleFactor, (float)scaleFactor);
								var imageRectangle = new Rectangle(0, 0, newWidth, newHeight);

								graphics.DrawImage(fullsizeImage, imageRectangle);

							}

							switch (mimeType)
							{
								case "image/jpeg":
									ImageCodecInfo codecInfo = GetEncoderInfo(mimeType);
									if (codecInfo == null) { return; }
									using (EncoderParameters encoderParams = new EncoderParameters(1))
									{
										long quality = 90;

										encoderParams.Param[0] = new EncoderParameter(System.Drawing.Imaging.Encoder.Quality, quality);
										//resizedBitmap.Save(imageFilePath, codecInfo, encoderParams);

										//deleting the file seems to be needed otherwise the resized smaller file is still the same size on disk
										// as the original
										fileSystem.DeleteFile(imageFilePath);
										// use a stream so we can support alternate file system providers
										using (Stream stream = fileSystem.GetWritableStream(imageFilePath))
										{
											resizedBitmap.Save(stream, codecInfo, encoderParams);
										}


									}

									break;


								case "image/gif":

									//deleting the file seems to be needed otherwise the resized smaller file is still the same size on disk
									// as the original
									fileSystem.DeleteFile(imageFilePath);

									//resizedBitmap.Save(imageFilePath, ImageFormat.Gif);
									using (Stream stream = fileSystem.GetWritableStream(imageFilePath))
									{
										resizedBitmap.Save(stream, ImageFormat.Gif);
									}
									break;

								case "image/png":

									//deleting the file seems to be needed otherwise the resized smaller file is still the same size on disk
									// as the original
									fileSystem.DeleteFile(imageFilePath);
									// use a stream
									//resizedBitmap.Save(imageFilePath, ImageFormat.Png);
									using (Stream stream = fileSystem.GetWritableStream(imageFilePath))
									{
										resizedBitmap.Save(stream, ImageFormat.Png);
									}
									break;

							}

						} //end using resized bitmap

					} //if (imageNeedsResizing)

				} //end using bitmap
			} //end using stream


		}
		catch (OutOfMemoryException ex)
		{
			log.Error(ex);
			return;
		}
		catch (ArgumentException ex)
		{
			log.Error(ex);
			return;
		}
		catch (System.Runtime.InteropServices.ExternalException ex)
		{
			log.Error(ex);
			return;
		}

		try
		{
			//if (File.Exists(tmpFilePath)) { File.Delete(tmpFilePath); }
			if (fileSystem.FileExists(tmpFilePath)) { fileSystem.DeleteFile(tmpFilePath); }
		}
		catch (ArgumentException) { }
		catch (IOException) { }
		catch (NotSupportedException) { }


	}

	/// <summary>
	/// http://weblogs.asp.net/gunnarpeipman/archive/2009/04/02/resizing-images-without-loss-of-quality.aspx
	/// http://nathanaeljones.com/11191_20_Image_Resizing_Pitfalls
	/// </summary>
	/// <param name="imageFilePath"></param>
	/// <param name="mimeType"></param>
	/// <param name="maxWidth"></param>
	/// <param name="maxHeight"></param>
	public static void ResizeAndSquareImage(string imageFilePath, string mimeType, int sideLength, Color backgroundColor)
	{
		var fileSystem = FileSystemHelper.LoadFileSystem();

		if (fileSystem is null || !fileSystem.FileExists(imageFilePath))
		{
			return;
		}

		string tmpFilePath = imageFilePath + ".tmp" + Path.GetExtension(imageFilePath);

		try
		{
			//we can't overwrite the same file we have open so first make a temp copy

			//File.Copy(imageFilePath, tmpFilePath, true);
			fileSystem.CopyFile(imageFilePath, tmpFilePath, true);

			//using (Image fullsizeImage = Image.FromFile(tmpFilePath))
			using (Stream tmpFileStream = fileSystem.GetAsStream(tmpFilePath))
			{
				using Image fullsizeImage = Image.FromStream(tmpFileStream);
				int a = Math.Min(fullsizeImage.Width, fullsizeImage.Height);
				var x = (fullsizeImage.Width - a) / 2;
				var y = (fullsizeImage.Height - a) / 2;

				using Bitmap resizedBitmap = new Bitmap(sideLength, sideLength, PixelFormat.Format24bppRgb);
				using (Graphics graphics = Graphics.FromImage(resizedBitmap))
				{
					graphics.CompositingQuality = CompositingQuality.HighQuality;
					graphics.SmoothingMode = SmoothingMode.HighQuality;
					graphics.InterpolationMode = InterpolationMode.HighQualityBicubic;
					//graphics.Clear(Color.White);
					if (backgroundColor != null) { graphics.Clear(backgroundColor); }

					var imageRectangle = new Rectangle(0, 0, sideLength, sideLength);

					graphics.DrawImage(fullsizeImage, imageRectangle, x, y, a, a, GraphicsUnit.Pixel);

				}

				switch (mimeType)
				{
					case "image/jpeg":
						ImageCodecInfo codecInfo = GetEncoderInfo(mimeType);
						if (codecInfo == null) { return; }
						using (EncoderParameters encoderParams = new EncoderParameters(1))
						{
							long quality = 90;

							encoderParams.Param[0] = new EncoderParameter(System.Drawing.Imaging.Encoder.Quality, quality);

							//deleting the file seems to be needed otherwise the resized smaller file is still the same size on disk
							// as the original
							fileSystem.DeleteFile(imageFilePath);
							using Stream stream = fileSystem.GetWritableStream(imageFilePath);
							resizedBitmap.Save(stream, codecInfo, encoderParams);
						}
						break;

					case "image/gif":

						//deleting the file seems to be needed otherwise the resized smaller file is still the same size on disk
						// as the original
						fileSystem.DeleteFile(imageFilePath);
						using (Stream stream = fileSystem.GetWritableStream(imageFilePath))
						{
							resizedBitmap.Save(stream, ImageFormat.Gif);
						}
						break;

					case "image/png":

						//deleting the file seems to be needed otherwise the resized smaller file is still the same size on disk
						// as the original
						fileSystem.DeleteFile(imageFilePath);
						//resizedBitmap.Save(imageFilePath, ImageFormat.Png);
						using (Stream stream = fileSystem.GetWritableStream(imageFilePath))
						{
							resizedBitmap.Save(stream, ImageFormat.Png);
						}
						break;
				}
			} //end using tmpFileStream

			fileSystem.DeleteFile(tmpFilePath);
		}
		catch (OutOfMemoryException ex)
		{
			log.Error(ex);
			return;
		}
		catch (ArgumentException ex)
		{
			log.Error(ex);
			return;
		}
		catch (System.Runtime.InteropServices.ExternalException ex)
		{
			log.Error(ex);
			return;
		}
	}

	/// <summary>
	/// crops an image and if destFilePath is not empty string it saves it as the new path. otherwise it updates the original
	/// </summary>
	/// <param name="imageFilePath"></param>
	/// <param name="destFilePath"></param>
	/// <param name="mimeType"></param>
	/// <param name="width"></param>
	/// <param name="height"></param>
	/// <param name="x"></param>
	/// <param name="y"></param>
	public static void CropImage(string imageFilePath, string destFilePath, string mimeType, int width, int height, int x, int y, Color backgroundColor)
	{
		var fileSystem = FileSystemHelper.LoadFileSystem();

		if (fileSystem is null || !fileSystem.FileExists(imageFilePath))
		{
			return;
		}

		string tmpFilePath = imageFilePath + ".tmp" + Path.GetExtension(imageFilePath);

		try
		{
			//we can't overwrite the same file we have open so first make a temp copy
			fileSystem.CopyFile(imageFilePath, tmpFilePath, true);

			using (Stream tmpFileStream = fileSystem.GetAsStream(tmpFilePath))
			{
				using Image fullsizeImage = Image.FromStream(tmpFileStream);
				using Bitmap resizedBitmap = new Bitmap(width, height, PixelFormat.Format24bppRgb);
				using (Graphics graphics = Graphics.FromImage(resizedBitmap))
				{
					graphics.CompositingQuality = CompositingQuality.HighQuality;
					graphics.SmoothingMode = SmoothingMode.HighQuality;
					graphics.InterpolationMode = InterpolationMode.HighQualityBicubic;
					//graphics.Clear(Color.White);
					if (backgroundColor != null) { graphics.Clear(backgroundColor); }

					var imageRectangle = new Rectangle(0, 0, width, height);

					graphics.DrawImage(fullsizeImage, imageRectangle, x, y, width, height, GraphicsUnit.Pixel);
				}

				switch (mimeType)
				{
					case "image/jpeg":
						ImageCodecInfo codecInfo = GetEncoderInfo(mimeType);
						if (codecInfo == null) { return; }
						using (EncoderParameters encoderParams = new EncoderParameters(1))
						{
							long quality = 90;

							encoderParams.Param[0] = new EncoderParameter(System.Drawing.Imaging.Encoder.Quality, quality);
							if (destFilePath.Length > 0)
							{
								//deleting the file seems to be needed otherwise the resized smaller file is still the same size on disk
								// as the original
								fileSystem.DeleteFile(destFilePath);
								//resizedBitmap.Save(destFilePath, codecInfo, encoderParams);
								using Stream stream = fileSystem.GetWritableStream(destFilePath);
								resizedBitmap.Save(stream, codecInfo, encoderParams);
							}
							else
							{
								//deleting the file seems to be needed otherwise the resized smaller file is still the same size on disk
								// as the original
								fileSystem.DeleteFile(imageFilePath);
								//resizedBitmap.Save(imageFilePath, codecInfo, encoderParams);
								using Stream stream = fileSystem.GetWritableStream(imageFilePath);
								resizedBitmap.Save(stream, codecInfo, encoderParams);
							}
						}

						break;


					case "image/gif":
						if (destFilePath.Length > 0)
						{
							//deleting the file seems to be needed otherwise the resized smaller file is still the same size on disk
							// as the original
							fileSystem.DeleteFile(destFilePath);
							//resizedBitmap.Save(destFilePath, ImageFormat.Gif);
							using Stream stream = fileSystem.GetWritableStream(destFilePath);
							resizedBitmap.Save(stream, ImageFormat.Gif);
						}
						else
						{
							//deleting the file seems to be needed otherwise the resized smaller file is still the same size on disk
							// as the original
							fileSystem.DeleteFile(imageFilePath);
							//resizedBitmap.Save(imageFilePath, ImageFormat.Gif);
							using Stream stream = fileSystem.GetWritableStream(imageFilePath);
							resizedBitmap.Save(stream, ImageFormat.Gif);
						}
						break;

					case "image/png":
						if (destFilePath.Length > 0)
						{
							//deleting the file seems to be needed otherwise the resized smaller file is still the same size on disk
							// as the original
							fileSystem.DeleteFile(destFilePath);
							//resizedBitmap.Save(destFilePath, ImageFormat.Png);
							using Stream stream = fileSystem.GetWritableStream(destFilePath);
							resizedBitmap.Save(stream, ImageFormat.Png);
						}
						else
						{
							//deleting the file seems to be needed otherwise the resized smaller file is still the same size on disk
							// as the original
							fileSystem.DeleteFile(imageFilePath);
							//resizedBitmap.Save(imageFilePath, ImageFormat.Png);
							using Stream stream = fileSystem.GetWritableStream(imageFilePath);
							resizedBitmap.Save(stream, ImageFormat.Png);
						}
						break;

				}
			} //end using tmpFileStream

			fileSystem.DeleteFile(tmpFilePath);
		}
		catch (OutOfMemoryException ex)
		{
			log.Error(ex);
			return;
		}
		catch (ArgumentException ex)
		{
			log.Error(ex);
			return;
		}
		catch (System.Runtime.InteropServices.ExternalException ex)
		{
			log.Error(ex);
			return;
		}
	}

	/// <summary>
	/// Gets image file extensions from web.config and adds * to each.
	/// </summary>
	/// <returns></returns>
	public static string[] GetImageExtensions()
	{
		//var imgExtensions = ConfigurationManager.AppSettings["ImageFileExtensions"] ?? ".gif|.jpg|.jpeg|.png|.svg|.webp";
		var imgExtensions = WebConfigSettings.ImageFileExtensions;

		// Split on pipe and append asterisk on each file extension
		return imgExtensions.Split('|').Select(i => $"*{i.Trim()}").ToArray();
	}

	public static void SetExifInformation(Bitmap bitmap, XmlDocument imageMetaData)
	{
		if ((bitmap != null) && (imageMetaData != null))
		{
			foreach (PropertyItem pi in bitmap.PropertyItems)
			{
				switch (pi.Id)
				{
					case 0x2: // GPSLatitude     


						PropertyItem gpsLatRef = bitmap.GetPropertyItem(0x1);

						double lat = ExifGpsToDouble(gpsLatRef, pi);
						if (lat != 0)
						{
							SetMetadata("GPSLatitude", lat.ToString(), imageMetaData);
						}
						else
						{
							SetMetadata("GPSLatitude", string.Empty, imageMetaData);
						}

						break;
					case 0x4: // GPSLongitude

						PropertyItem gpsLongRef = bitmap.GetPropertyItem(0x3);

						double longi = ExifGpsToDouble(gpsLongRef, pi);
						if (longi != 0)
						{
							SetMetadata("GPSLongitude", longi.ToString(), imageMetaData);
						}
						else
						{
							SetMetadata("GPSLongitude", string.Empty, imageMetaData);
						}


						break;
					case 0x6: // GPSAltitude
						int alti = BitConverter.ToInt32(pi.Value, 0);
						SetMetadata("GPSAltitude", alti.ToString(), imageMetaData);
						break;

					case 0x010F:
						SetMetadata("EquipMake", ConvertByteArrayToString(pi.Value), imageMetaData);
						break;

					case 0x0110:
						SetMetadata("EquipModel", ConvertByteArrayToString(pi.Value), imageMetaData);
						break;

					case 0x0112:
						switch (ConvertByteArrayToShort(pi.Value))
						{
							case 1:
								SetMetadata("Orientation", "upper left", imageMetaData);
								break;
							case 2:
								SetMetadata("Orientation", "upper right", imageMetaData);
								break;
							case 3:
								SetMetadata("Orientation", "lower right", imageMetaData);
								break;
							case 4:
								SetMetadata("Orientation", "lower left", imageMetaData);
								break;
							case 5:
								SetMetadata("Orientation", "upper left flipped", imageMetaData);
								break;
							case 6:
								SetMetadata("Orientation", "upper right flipped", imageMetaData);
								break;
							case 7:
								SetMetadata("Orientation", "lower right flipped", imageMetaData);
								break;
							case 8:
								SetMetadata("Orientation", "lower left flipped", imageMetaData);
								break;
						}
						break;
					case 0x011a:
						SetMetadata("XResolution", ConvertByteArrayToRational(pi.Value), imageMetaData);
						break;
					case 0x011b:
						SetMetadata("YResolution", ConvertByteArrayToRational(pi.Value), imageMetaData);
						break;
					case 0x0128:
						SetMetadata("ResolutionUnit", ConvertByteArrayToShort(pi.Value).ToString(), imageMetaData);
						break;
					case 0x0132:
						SetMetadata("Datetime", ConvertByteArrayToString(pi.Value), imageMetaData);
						break;
					case 0x0213:
						SetMetadata("YCbCrPositioning", ConvertByteArrayToShort(pi.Value).ToString(), imageMetaData);
						break;
					case 0x00FE:
						SetMetadata("NewSubfileType", ConvertByteArrayToLong(pi.Value).ToString(), imageMetaData);
						break;
					case 0x00FF:
						SetMetadata("SubfileType", ConvertByteArrayToShort(pi.Value).ToString(), imageMetaData);
						break;
					case 0x0100:
						SetMetadata("ImageWidth", ConvertByteArrayToLong(pi.Value).ToString(), imageMetaData);
						break;
					case 0x0101:
						SetMetadata("ImageHeight", ConvertByteArrayToLong(pi.Value).ToString(), imageMetaData);
						break;
					case 0x0102:
						SetMetadata("BitsPerSample", ConvertByteArrayToShort(pi.Value).ToString(), imageMetaData);
						break;
					case 0x0103:
						SetMetadata("Compression", ConvertByteArrayToShort(pi.Value).ToString(), imageMetaData);
						break;
					case 0x0106:
						SetMetadata("PhotometricInterp", ConvertByteArrayToShort(pi.Value).ToString(), imageMetaData);
						break;
					case 0x0107:
						SetMetadata("ThreshHolding", ConvertByteArrayToShort(pi.Value).ToString(), imageMetaData);
						break;
					case 0x0108:
						SetMetadata("CellWidth", ConvertByteArrayToShort(pi.Value).ToString(), imageMetaData);
						break;
					case 0x0109:
						SetMetadata("CellHeight", ConvertByteArrayToShort(pi.Value).ToString(), imageMetaData);
						break;
					case 0x010A:
						SetMetadata("FillOrder", ConvertByteArrayToShort(pi.Value).ToString(), imageMetaData);
						break;
					case 0x010D:
						SetMetadata("DocumentName", ConvertByteArrayToString(pi.Value), imageMetaData);
						break;
					case 0x010E:
						SetMetadata("ImageDescription", ConvertByteArrayToString(pi.Value), imageMetaData);
						break;
					case 0x0111:
						SetMetadata("StripOffsets", ConvertByteArrayToLong(pi.Value).ToString(), imageMetaData);
						break;
					case 0x0115:
						SetMetadata("SamplesPerPixel", ConvertByteArrayToShort(pi.Value).ToString(), imageMetaData);
						break;
					case 0x0116:
						SetMetadata("RowsPerStrip", ConvertByteArrayToLong(pi.Value).ToString(), imageMetaData);
						break;
					case 0x0117:
						SetMetadata("StripBytesCount", ConvertByteArrayToLong(pi.Value).ToString(), imageMetaData);
						break;
					case 0x0118:
						SetMetadata("MinSampleValue", ConvertByteArrayToShort(pi.Value).ToString(), imageMetaData);
						break;
					case 0x0119:
						SetMetadata("MaxSampleValue", ConvertByteArrayToShort(pi.Value).ToString(), imageMetaData);
						break;
					case 0x011C:
						SetMetadata("PlanarConfig", ConvertByteArrayToShort(pi.Value).ToString(), imageMetaData);
						break;
					case 0x011D:
						SetMetadata("PageName", ConvertByteArrayToString(pi.Value), imageMetaData);
						break;
					case 0x011E:
						SetMetadata("XPosition", ConvertByteArrayToRational(pi.Value), imageMetaData);
						break;
					case 0x011F:
						SetMetadata("YPosition", ConvertByteArrayToRational(pi.Value), imageMetaData);
						break;
					case 0x0120:
						SetMetadata("FreeOffset", ConvertByteArrayToLong(pi.Value).ToString(), imageMetaData);
						break;
					case 0x0121:
						SetMetadata("FreeByteCounts", ConvertByteArrayToLong(pi.Value).ToString(), imageMetaData);
						break;
					case 0x0122:
						SetMetadata("GrayResponseUnit", ConvertByteArrayToShort(pi.Value).ToString(), imageMetaData);
						break;
					case 0x0123:
						SetMetadata("GrayResponseCurve", ConvertByteArrayToShort(pi.Value).ToString(), imageMetaData);
						break;
					case 0x0124:
						SetMetadata("T4Option", ConvertByteArrayToLong(pi.Value).ToString(), imageMetaData);
						break;
					case 0x0125:
						SetMetadata("T6Option", ConvertByteArrayToLong(pi.Value).ToString(), imageMetaData);
						break;
					case 0x0129:
						SetMetadata("PageNumber", ConvertByteArrayToShort(pi.Value).ToString(), imageMetaData);
						break;
					case 0x012D:
						SetMetadata("TransferFunction", ConvertByteArrayToShort(pi.Value).ToString(), imageMetaData);
						break;
					case 0x0131:
						SetMetadata("SoftwareUsed", ConvertByteArrayToString(pi.Value), imageMetaData);
						break;
					case 0x013B:
						SetMetadata("Artist", ConvertByteArrayToString(pi.Value), imageMetaData);
						break;
					case 0x013C:
						SetMetadata("HostComputer", ConvertByteArrayToString(pi.Value), imageMetaData);
						break;
					case 0x013D:
						SetMetadata("Predictor", ConvertByteArrayToShort(pi.Value).ToString(), imageMetaData);
						break;
					case 0x013E:
						SetMetadata("WhitePoint", ConvertByteArrayToRational(pi.Value), imageMetaData);
						break;
					case 0x013F:
						SetMetadata("PrimaryChromaticities", ConvertByteArrayToRational(pi.Value), imageMetaData);
						break;
					case 0x0140:
						SetMetadata("ColorMap", ConvertByteArrayToShort(pi.Value).ToString(), imageMetaData);
						break;
					case 0x0141:
						SetMetadata("HalftoneHints", ConvertByteArrayToShort(pi.Value).ToString(), imageMetaData);
						break;
					case 0x0142:
						SetMetadata("TileWidth", ConvertByteArrayToLong(pi.Value).ToString(), imageMetaData);
						break;
					case 0x0143:
						SetMetadata("TileLength", ConvertByteArrayToLong(pi.Value).ToString(), imageMetaData);
						break;
					case 0x0144:
						SetMetadata("TileOffset", ConvertByteArrayToLong(pi.Value).ToString(), imageMetaData);
						break;
					case 0x0145:
						SetMetadata("TileByteCounts", ConvertByteArrayToLong(pi.Value).ToString(), imageMetaData);
						break;
					case 0x014C:
						SetMetadata("InkSet", ConvertByteArrayToShort(pi.Value).ToString(), imageMetaData);
						break;
					case 0x014D:
						SetMetadata("InkNames", ConvertByteArrayToString(pi.Value), imageMetaData);
						break;
					case 0x014E:
						SetMetadata("NumberOfInks", ConvertByteArrayToShort(pi.Value).ToString(), imageMetaData);
						break;
					case 0x0150:
						SetMetadata("DotRange", ConvertByteArrayToShort(pi.Value).ToString(), imageMetaData);
						break;
					case 0x0151:
						SetMetadata("TargetPrinter", ConvertByteArrayToString(pi.Value), imageMetaData);
						break;
					case 0x0152:
						SetMetadata("ExtraSamples", ConvertByteArrayToShort(pi.Value).ToString(), imageMetaData);
						break;
					case 0x0153:
						SetMetadata("SampleFormat", ConvertByteArrayToShort(pi.Value).ToString(), imageMetaData);
						break;
					case 0x0156:
						SetMetadata("TransferRange", ConvertByteArrayToShort(pi.Value).ToString(), imageMetaData);
						break;
					case 0x0200:
						SetMetadata("JPEGProc", ConvertByteArrayToShort(pi.Value).ToString(), imageMetaData);
						break;
					case 0x0201:
						SetMetadata("JPEGInterFormat", ConvertByteArrayToLong(pi.Value).ToString(), imageMetaData);
						break;
					case 0x0202:
						SetMetadata("JPEGInterLength", ConvertByteArrayToLong(pi.Value).ToString(), imageMetaData);
						break;
					case 0x0203:
						SetMetadata("JPEGRestartInterval", ConvertByteArrayToShort(pi.Value).ToString(), imageMetaData);
						break;
					case 0x0205:
						SetMetadata("JPEGLosslessPredictors", ConvertByteArrayToShort(pi.Value).ToString(), imageMetaData);
						break;
					case 0x0206:
						SetMetadata("JPEGPointTransforms", ConvertByteArrayToShort(pi.Value).ToString(), imageMetaData);
						break;
					case 0x0207:
						SetMetadata("JPEGQTables", ConvertByteArrayToLong(pi.Value).ToString(), imageMetaData);
						break;
					case 0x0208:
						SetMetadata("JPEGDCTables", ConvertByteArrayToLong(pi.Value).ToString(), imageMetaData);
						break;
					case 0x0209:
						SetMetadata("JPEGACTables", ConvertByteArrayToLong(pi.Value).ToString(), imageMetaData);
						break;
					case 0x0211:
						SetMetadata("YCbCrCoefficients", ConvertByteArrayToRational(pi.Value), imageMetaData);
						break;
					case 0x0212:
						SetMetadata("YCbCrSubsampling", ConvertByteArrayToShort(pi.Value).ToString(), imageMetaData);
						break;
					case 0x0214:
						SetMetadata("REFBlackWhite", ConvertByteArrayToRational(pi.Value), imageMetaData);
						break;
					case 0x0301:
						SetMetadata("Gamma", ConvertByteArrayToRational(pi.Value), imageMetaData);
						break;
					case 0x0302:
						SetMetadata("ICCProfileDescriptor", ConvertByteArrayToString(pi.Value), imageMetaData);
						break;
					case 0x0303:
						switch (ConvertByteArrayToShort(pi.Value))
						{
							case 0:
								SetMetadata("SRGBRenderingIntent", "perceptual", imageMetaData);
								break;
							case 1:
								SetMetadata("SRGBRenderingIntent", "relative colorimetric", imageMetaData);
								break;
							case 2:
								SetMetadata("SRGBRenderingIntent", "saturation", imageMetaData);
								break;
							case 3:
								SetMetadata("SRGBRenderingIntent", "absolute colorimetric", imageMetaData);
								break;
						}
						break;
					case 0x0320:
						SetMetadata("ImageTitle", ConvertByteArrayToString(pi.Value), imageMetaData);
						break;
					case 0x5001:
						SetMetadata("ResolutionXUnit", ConvertByteArrayToShort(pi.Value).ToString(), imageMetaData);
						break;
					case 0x5002:
						SetMetadata("ResolutionYUnit", ConvertByteArrayToShort(pi.Value).ToString(), imageMetaData);
						break;
					case 0x5003:
						SetMetadata("ResolutionXLengthUnit", ConvertByteArrayToShort(pi.Value).ToString(), imageMetaData);
						break;
					case 0x5004:
						SetMetadata("ResolutionYLengthUnit", ConvertByteArrayToShort(pi.Value).ToString(), imageMetaData);
						break;
					case 0x5005:
						SetMetadata("PrintFlags", ConvertByteArrayToString(pi.Value), imageMetaData);
						break;
					case 0x5006:
						SetMetadata("PrintFlagsVersion", ConvertByteArrayToShort(pi.Value).ToString(), imageMetaData);
						break;
					case 0x5007:
						SetMetadata("PrintFlagsCrop", ConvertByteArrayToByte(pi.Value).ToString(), imageMetaData);
						break;
					case 0x5008:
						SetMetadata("PrintFlagsBleedWidth", ConvertByteArrayToLong(pi.Value).ToString(), imageMetaData);
						break;
					case 0x5009:
						SetMetadata("PrintFlagsBleedWidthScale", ConvertByteArrayToShort(pi.Value).ToString(), imageMetaData);
						break;
					case 0x500A:
						SetMetadata("HalftoneLPI", ConvertByteArrayToRational(pi.Value), imageMetaData);
						break;
					case 0x500B:
						SetMetadata("HalftoneLPIUnit", ConvertByteArrayToShort(pi.Value).ToString(), imageMetaData);
						break;
					case 0x500C:
						SetMetadata("HalftoneDegree", ConvertByteArrayToRational(pi.Value), imageMetaData);
						break;
					case 0x500D:
						SetMetadata("HalftoneShape", ConvertByteArrayToShort(pi.Value).ToString(), imageMetaData);
						break;
					case 0x500E:
						SetMetadata("HalftoneMisc", ConvertByteArrayToLong(pi.Value).ToString(), imageMetaData);
						break;
					case 0x500F:
						SetMetadata("HalftoneScreen", ConvertByteArrayToByte(pi.Value).ToString(), imageMetaData);
						break;
					case 0x5010:
						SetMetadata("JPEGQuality", ConvertByteArrayToShort(pi.Value).ToString(), imageMetaData);
						break;
					case 0x5012:
						SetMetadata("ThumbnailFormat", ConvertByteArrayToLong(pi.Value).ToString(), imageMetaData);
						break;
					case 0x5013:
						SetMetadata("ThumbnailWidth", ConvertByteArrayToLong(pi.Value).ToString(), imageMetaData);
						break;
					case 0x5014:
						SetMetadata("ThumbnailHeight", ConvertByteArrayToLong(pi.Value).ToString(), imageMetaData);
						break;
					case 0x5015:
						SetMetadata("ThumbnailColorDepth", ConvertByteArrayToShort(pi.Value).ToString(), imageMetaData);
						break;
					case 0x5016:
						SetMetadata("ThumbnailPlanes", ConvertByteArrayToShort(pi.Value).ToString(), imageMetaData);
						break;
					case 0x5017:
						SetMetadata("ThumbnailRawBytes", ConvertByteArrayToLong(pi.Value).ToString(), imageMetaData);
						break;
					case 0x5018:
						SetMetadata("ThumbnailSize", ConvertByteArrayToLong(pi.Value).ToString(), imageMetaData);
						break;
					case 0x5019:
						SetMetadata("ThumbnailCompressedSize", ConvertByteArrayToLong(pi.Value).ToString(), imageMetaData);
						break;
					case 0x501B:
						SetMetadata("ThumbnailData", ConvertByteArrayToByte(pi.Value).ToString(), imageMetaData);
						break;
					case 0x5020:
						SetMetadata("ThumbnailImageWidth", ConvertByteArrayToLong(pi.Value).ToString(), imageMetaData);
						break;
					case 0x5021:
						SetMetadata("ThumbnailImageHeight", ConvertByteArrayToLong(pi.Value).ToString(), imageMetaData);
						break;
					case 0x5022:
						SetMetadata("ThumbnailBitsPerSample", ConvertByteArrayToShort(pi.Value).ToString(), imageMetaData);
						break;
					case 0x5023:
						SetMetadata("ThumbnailCompression", ConvertByteArrayToShort(pi.Value).ToString(), imageMetaData);
						break;
					case 0x5024:
						SetMetadata("ThumbnailPhotometricInterp", ConvertByteArrayToShort(pi.Value).ToString(), imageMetaData);
						break;
					case 0x5025:
						SetMetadata("ThumbnailImageDescription", ConvertByteArrayToString(pi.Value), imageMetaData);
						break;
					case 0x5026:
						SetMetadata("ThumbnailEquipMake", ConvertByteArrayToString(pi.Value), imageMetaData);
						break;
					case 0x5027:
						SetMetadata("ThumbnailEquipModel", ConvertByteArrayToString(pi.Value), imageMetaData);
						break;
					case 0x5028:
						SetMetadata("ThumbnailStripOffsets", ConvertByteArrayToLong(pi.Value).ToString(), imageMetaData);
						break;
					case 0x5029:
						SetMetadata("ThumbnailOrientation", ConvertByteArrayToShort(pi.Value).ToString(), imageMetaData);
						break;
					case 0x502A:
						SetMetadata("ThumbnailSamplesPerPixel", ConvertByteArrayToShort(pi.Value).ToString(), imageMetaData);
						break;
					case 0x502B:
						SetMetadata("ThumbnailRowsPerStrip", ConvertByteArrayToLong(pi.Value).ToString(), imageMetaData);
						break;
					case 0x502C:
						SetMetadata("ThumbnailStripBytesCount", ConvertByteArrayToLong(pi.Value).ToString(), imageMetaData);
						break;
					case 0x502F:
						SetMetadata("ThumbnailPlanarConfig", ConvertByteArrayToShort(pi.Value).ToString(), imageMetaData);
						break;
					case 0x5030:
						SetMetadata("ThumbnailResolutionUnit", ConvertByteArrayToShort(pi.Value).ToString(), imageMetaData);
						break;
					case 0x5031:
						SetMetadata("ThumbnailTransferFunction", ConvertByteArrayToShort(pi.Value).ToString(), imageMetaData);
						break;
					case 0x5032:
						SetMetadata("ThumbnailSoftwareUsed", ConvertByteArrayToString(pi.Value), imageMetaData);
						break;
					case 0x5033:
						SetMetadata("ThumbnailDateTime", ConvertByteArrayToString(pi.Value), imageMetaData);
						break;
					case 0x5034:
						SetMetadata("ThumbnailArtist", ConvertByteArrayToString(pi.Value), imageMetaData);
						break;
					case 0x5035:
						SetMetadata("ThumbnailWhitePoint", ConvertByteArrayToRational(pi.Value), imageMetaData);
						break;
					case 0x5036:
						SetMetadata("ThumbnailPrimaryChromaticities", ConvertByteArrayToRational(pi.Value), imageMetaData);
						break;
					case 0x5037:
						SetMetadata("ThumbnailYCbCrCoefficients", ConvertByteArrayToRational(pi.Value), imageMetaData);
						break;
					case 0x5038:
						SetMetadata("ThumbnailYCbCrSubsampling", ConvertByteArrayToShort(pi.Value).ToString(), imageMetaData);
						break;
					case 0x5039:
						SetMetadata("ThumbnailYCbCrPositioning", ConvertByteArrayToShort(pi.Value).ToString(), imageMetaData);
						break;
					case 0x503A:
						SetMetadata("ThumbnailRefBlackWhite", ConvertByteArrayToRational(pi.Value), imageMetaData);
						break;
					case 0x503B:
						SetMetadata("ThumbnailCopyRight", ConvertByteArrayToString(pi.Value), imageMetaData);
						break;
					case 0x5090:
						SetMetadata("LuminanceTable", ConvertByteArrayToShort(pi.Value).ToString(), imageMetaData);
						break;
					case 0x5091:
						SetMetadata("ChrominanceTable", ConvertByteArrayToShort(pi.Value).ToString(), imageMetaData);
						break;
					case 0x5100:
						SetMetadata("FrameDelay", ConvertByteArrayToLong(pi.Value).ToString(), imageMetaData);
						break;
					case 0x5101:
						SetMetadata("LoopCount", ConvertByteArrayToShort(pi.Value).ToString(), imageMetaData);
						break;
					case 0x5110:
						SetMetadata("PixelUnit", ConvertByteArrayToByte(pi.Value).ToString(), imageMetaData);
						break;
					case 0x5111:
						SetMetadata("PixelPerUnitX", ConvertByteArrayToLong(pi.Value).ToString(), imageMetaData);
						break;
					case 0x5112:
						SetMetadata("PixelPerUnitY", ConvertByteArrayToLong(pi.Value).ToString(), imageMetaData);
						break;
					case 0x5113:
						SetMetadata("PaletteHistogram", ConvertByteArrayToByte(pi.Value).ToString(), imageMetaData);
						break;
					case 0x8298:
						SetMetadata("Copyright", ConvertByteArrayToString(pi.Value), imageMetaData);
						break;
					case 0x829A:
						SetMetadata("ExifExposureTime", ConvertByteArrayToRational(pi.Value), imageMetaData);
						break;
					case 0x829D:
						SetMetadata("ExifFNumber", ConvertByteArrayToRational(pi.Value), imageMetaData);
						break;
					case 0x8769:
						SetMetadata("ExifIFD", ConvertByteArrayToLong(pi.Value).ToString(), imageMetaData);
						break;
					case 0x8773:
						SetMetadata("ICCProfile", ConvertByteArrayToByte(pi.Value).ToString(), imageMetaData);
						break;
					case 0x8822:
						switch (ConvertByteArrayToShort(pi.Value))
						{
							case 0:
								SetMetadata("ExifExposureProg", "Not defined", imageMetaData);
								break;
							case 1:
								SetMetadata("ExifExposureProg", "Manual", imageMetaData);
								break;
							case 2:
								SetMetadata("ExifExposureProg", "Normal Program", imageMetaData);
								break;
							case 3:
								SetMetadata("ExifExposureProg", "Aperture Priority", imageMetaData);
								break;
							case 4:
								SetMetadata("ExifExposureProg", "Shutter Priority", imageMetaData);
								break;
							case 5:
								SetMetadata("ExifExposureProg", "Creative program (biased toward depth of field)", imageMetaData);
								break;
							case 6:
								SetMetadata("ExifExposureProg", "Action program (biased toward fast shutter speed)", imageMetaData);
								break;
							case 7:
								SetMetadata("ExifExposureProg", "Portrait mode (for close-up photos with the background out of focus)", imageMetaData);
								break;
							case 8:
								SetMetadata("ExifExposureProg", "Landscape mode (for landscape photos with the background in focus)", imageMetaData);
								break;
							default:
								SetMetadata("ExifExposureProg", "Unknown", imageMetaData);
								break;
						}
						break;
					case 0x8824:
						SetMetadata("ExifSpectralSense", ConvertByteArrayToString(pi.Value), imageMetaData);
						break;
					case 0x8825:
						SetMetadata("GpsIFD", ConvertByteArrayToLong(pi.Value).ToString(), imageMetaData);
						break;
					case 0x8827:
						SetMetadata("ExifISOSpeed", ConvertByteArrayToShort(pi.Value).ToString(), imageMetaData);
						break;
					case 0x9003:
						SetMetadata("ExifDTOrig", ConvertByteArrayToString(pi.Value), imageMetaData);
						break;
					case 0x9004:
						SetMetadata("ExifDTDigitized", ConvertByteArrayToString(pi.Value), imageMetaData);
						break;
					case 0x9102:
						SetMetadata("ExifCompBPP", ConvertByteArrayToRational(pi.Value), imageMetaData);
						break;
					case 0x9201:
						SetMetadata("ExifShutterSpeed", ConvertByteArrayToSRational(pi.Value), imageMetaData);
						break;
					case 0x9202:
						SetMetadata("ExifAperture", ConvertByteArrayToRational(pi.Value), imageMetaData);
						break;
					case 0x9203:
						SetMetadata("ExifBrightness", ConvertByteArrayToSRational(pi.Value), imageMetaData);
						break;
					case 0x9204:
						SetMetadata("ExifExposureBias", ConvertByteArrayToSRational(pi.Value), imageMetaData);
						break;
					case 0x9205:
						SetMetadata("ExifMaxAperture", ConvertByteArrayToRational(pi.Value), imageMetaData);
						break;
					case 0x9206:
						SetMetadata("ExifSubjectDist", ConvertByteArrayToRational(pi.Value), imageMetaData);
						break;
					case 0x9207:
						switch (ConvertByteArrayToShort(pi.Value))
						{
							case 0:
								SetMetadata("ExifMeteringMode", "Unknown", imageMetaData);
								break;
							case 1:
								SetMetadata("ExifMeteringMode", "Average", imageMetaData);
								break;
							case 2:
								SetMetadata("ExifMeteringMode", "CenterWeightedAverage", imageMetaData);
								break;
							case 3:
								SetMetadata("ExifMeteringMode", "Spot", imageMetaData);
								break;
							case 4:
								SetMetadata("ExifMeteringMode", "MultiSpot", imageMetaData);
								break;
							case 5:
								SetMetadata("ExifMeteringMode", "Pattern", imageMetaData);
								break;
							case 6:
								SetMetadata("ExifMeteringMode", "Partial", imageMetaData);
								break;
							case 255:
								SetMetadata("ExifMeteringMode", "Other", imageMetaData);
								break;
							default:
								SetMetadata("ExifMeteringMode", "Unknown", imageMetaData);
								break;
						}
						break;
					case 0x9208:
						switch (ConvertByteArrayToShort(pi.Value))
						{
							case 0:
								SetMetadata("ExifLightSource", "Unknown", imageMetaData);
								break;
							case 1:
								SetMetadata("ExifLightSource", "Daylight", imageMetaData);
								break;
							case 2:
								SetMetadata("ExifLightSource", "Flourescent", imageMetaData);
								break;
							case 3:
								SetMetadata("ExifLightSource", "Tungsten", imageMetaData);
								break;
							case 17:
								SetMetadata("ExifLightSource", "Standard Light A", imageMetaData);
								break;
							case 18:
								SetMetadata("ExifLightSource", "Standard Light B", imageMetaData);
								break;
							case 19:
								SetMetadata("ExifLightSource", "Standard Light C", imageMetaData);
								break;
							case 20:
								SetMetadata("ExifLightSource", "D55", imageMetaData);
								break;
							case 21:
								SetMetadata("ExifLightSource", "D65", imageMetaData);
								break;
							case 22:
								SetMetadata("ExifLightSource", "D75", imageMetaData);
								break;
							case 255:
								SetMetadata("ExifLightSource", "Other", imageMetaData);
								break;
							default:
								SetMetadata("ExifLightSource", "Unknown", imageMetaData);
								break;
						}
						break;
					case 0x9209:
						switch (ConvertByteArrayToShort(pi.Value))
						{
							case 0:
								SetMetadata("ExifFlash", "Flash did not fire", imageMetaData);
								break;
							case 1:
								SetMetadata("ExifFlash", "Flash fired", imageMetaData);
								break;
							case 5:
								SetMetadata("ExifFlash", "Strobe return light not detected", imageMetaData);
								break;
							default:
								SetMetadata("ExifFlash", "Uknown", imageMetaData);
								break;
						}
						break;
					case 0x920A:
						SetMetadata("ExifFocalLength", ConvertByteArrayToRational(pi.Value), imageMetaData);
						break;
					case 0x9290:
						SetMetadata("ExifDTSubsec", ConvertByteArrayToString(pi.Value), imageMetaData);
						break;
					case 0x9291:
						SetMetadata("ExifDTOrigSS", ConvertByteArrayToString(pi.Value), imageMetaData);
						break;
					case 0x9292:
						SetMetadata("ExifDTDigSS", ConvertByteArrayToString(pi.Value), imageMetaData);
						break;
					case 0xA001:
						switch (ConvertByteArrayToLong(pi.Value))
						{
							case 0x1:
								SetMetadata("ExifColorSpace", "sRGB", imageMetaData);
								break;
							case 0xFFFF:
								SetMetadata("ExifColorSpace", "Uncalibrated", imageMetaData);
								break;
							default:
								SetMetadata("ExifColorSpace", "Reserved", imageMetaData);
								break;
						}
						break;
					case 0xA002:
						SetMetadata("ExifPixXDim", ConvertByteArrayToLong(pi.Value).ToString(), imageMetaData);
						break;
					case 0xA003:
						SetMetadata("ExifPixYDim", ConvertByteArrayToLong(pi.Value).ToString(), imageMetaData);
						break;
					case 0xA004:
						SetMetadata("ExifRelatedWav", ConvertByteArrayToString(pi.Value), imageMetaData);
						break;
					case 0xA005:
						SetMetadata("ExifInterop", ConvertByteArrayToLong(pi.Value).ToString(), imageMetaData);
						break;
					case 0xA20B:
						SetMetadata("ExifFlashEnergy", ConvertByteArrayToRational(pi.Value), imageMetaData);
						break;
					case 0xA20E:
						SetMetadata("ExifFocalXRes", ConvertByteArrayToRational(pi.Value), imageMetaData);
						break;
					case 0xA20F:
						SetMetadata("ExifFocalYRes", ConvertByteArrayToRational(pi.Value), imageMetaData);
						break;
					case 0xA210:
						switch (ConvertByteArrayToShort(pi.Value))
						{
							case 2:
								SetMetadata("ExifFocalResUnit", "Inch", imageMetaData);
								break;
							case 3:
								SetMetadata("ExifFocalResUnit", "Centimeter", imageMetaData);
								break;
						}
						break;
					case 0xA214:
						SetMetadata("ExifSubjectLoc", ConvertByteArrayToShort(pi.Value).ToString(), imageMetaData);
						break;
					case 0xA215:
						SetMetadata("ExifExposureIndex", ConvertByteArrayToRational(pi.Value), imageMetaData);
						break;
					case 0xA217:
						switch (ConvertByteArrayToShort(pi.Value))
						{
							case 1:
								SetMetadata("ExifSensingMethod", "Not defined", imageMetaData);
								break;
							case 2:
								SetMetadata("ExifSensingMethod", "One-chip color area sensor", imageMetaData);
								break;
							case 3:
								SetMetadata("ExifSensingMethod", "Two-chip color area sensor", imageMetaData);
								break;
							case 4:
								SetMetadata("ExifSensingMethod", "Three-chip color area sensor", imageMetaData);
								break;
							case 5:
								SetMetadata("ExifSensingMethod", "Color sequential area sensor", imageMetaData);
								break;
							case 7:
								SetMetadata("ExifSensingMethod", "Trilinear sensor", imageMetaData);
								break;
							case 8:
								SetMetadata("ExifSensingMethod", "Color sequential linear sensor", imageMetaData);
								break;
							default:
								SetMetadata("ExifSensingMethod", "Reserved", imageMetaData);
								break;
						}
						break;
				}
			}
		}
	}

	/*	The following is from https://www.ryadel.com/en/change-image-orientation-iphone-andor-android-phone-pics-net-c 
		This fixes issues where photos taken on iPhones contain an EXIF tag with the proper orientation of the photo.
	 */

	/// <summary>
	/// Rotate the given image file according to Exif Orientation data
	/// </summary>
	/// <param name="sourceFilePath">path of source file</param>
	/// <param name="targetFilePath">path of target file</param>
	/// <param name="targetFormat">target format</param>
	/// <param name="updateExifData">set it to TRUE to update image Exif data after rotation (default is TRUE)</param>
	/// <returns>The RotateFlipType value corresponding to the applied rotation. If no rotation occurred, RotateFlipType.RotateNoneFlipNone will be returned.</returns>
	public static RotateFlipType RotateImageByExifOrientationData(string sourceFilePath, string targetFilePath, ImageFormat targetFormat, bool updateExifData = true)
	{
		// Rotate the image according to EXIF data
		var bmp = new Bitmap(sourceFilePath);
		RotateFlipType fType = RotateImageByExifOrientationData(bmp, updateExifData);
		if (fType != RotateFlipType.RotateNoneFlipNone)
		{
			bmp.Save(targetFilePath, targetFormat);
		}
		return fType;
	}

	/// <summary>
	/// Rotate the given bitmap according to Exif Orientation data
	/// </summary>
	/// <param name="img">source image</param>
	/// <param name="updateExifData">set it to TRUE to update image Exif data after rotation (default is TRUE)</param>
	/// <returns>The RotateFlipType value corresponding to the applied rotation. If no rotation occurred, RotateFlipType.RotateNoneFlipNone will be returned.</returns>
	public static RotateFlipType RotateImageByExifOrientationData(Image img, bool updateExifData = true)
	{
		int orientationId = 0x0112;
		var fType = RotateFlipType.RotateNoneFlipNone;
		if (img.PropertyIdList.Contains(orientationId))
		{
			var pItem = img.GetPropertyItem(orientationId);
			fType = GetRotateFlipTypeByExifOrientationData(pItem.Value[0]);
			if (fType != RotateFlipType.RotateNoneFlipNone)
			{
				img.RotateFlip(fType);
				if (updateExifData) img.RemovePropertyItem(orientationId); // Remove Exif orientation tag
			}
		}
		return fType;
	}

	/// <summary>
	/// Return the proper System.Drawing.RotateFlipType according to given orientation EXIF metadata
	/// </summary>
	/// <param name="orientation">Exif "Orientation"</param>
	/// <returns>the corresponding System.Drawing.RotateFlipType enum value</returns>
	public static RotateFlipType GetRotateFlipTypeByExifOrientationData(int orientation)
	{
		switch (orientation)
		{
			case 1:
			default:
				return RotateFlipType.RotateNoneFlipNone;
			case 2:
				return RotateFlipType.RotateNoneFlipX;
			case 3:
				return RotateFlipType.Rotate180FlipNone;
			case 4:
				return RotateFlipType.Rotate180FlipX;
			case 5:
				return RotateFlipType.Rotate90FlipX;
			case 6:
				return RotateFlipType.Rotate90FlipNone;
			case 7:
				return RotateFlipType.Rotate270FlipX;
			case 8:
				return RotateFlipType.Rotate270FlipNone;
		}
	}

	#endregion
}