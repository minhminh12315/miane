namespace BuildingBlocks.Validation;

/// <summary>
/// Detects common image formats from magic bytes so uploads cannot rely on
/// a spoofed file extension alone.
/// </summary>
public static class ImageMagicBytes
{
    public static bool TryGetExtension(Stream content, out string extension)
    {
        extension = string.Empty;
        if (!content.CanSeek)
        {
            return false;
        }

        var originalPosition = content.Position;
        try
        {
            Span<byte> header = stackalloc byte[12];
            var read = content.Read(header);
            if (read < 3)
            {
                return false;
            }

            if (header[0] == 0xFF && header[1] == 0xD8 && header[2] == 0xFF)
            {
                extension = ".jpg";
                return true;
            }

            if (read >= 8
                && header[0] == 0x89 && header[1] == 0x50 && header[2] == 0x4E && header[3] == 0x47
                && header[4] == 0x0D && header[5] == 0x0A && header[6] == 0x1A && header[7] == 0x0A)
            {
                extension = ".png";
                return true;
            }

            if (read >= 12
                && header[0] == (byte)'R' && header[1] == (byte)'I' && header[2] == (byte)'F' && header[3] == (byte)'F'
                && header[8] == (byte)'W' && header[9] == (byte)'E' && header[10] == (byte)'B' && header[11] == (byte)'P')
            {
                extension = ".webp";
                return true;
            }

            // HEIC/HEIF often starts with ....ftypheic / ftypheif / ftypmif1
            if (read >= 12
                && header[4] == (byte)'f' && header[5] == (byte)'t' && header[6] == (byte)'y' && header[7] == (byte)'p')
            {
                var brand = System.Text.Encoding.ASCII.GetString(header.Slice(8, 4));
                if (brand is "heic" or "heif" or "mif1" or "msf1")
                {
                    extension = ".heic";
                    return true;
                }
            }

            return false;
        }
        finally
        {
            content.Position = originalPosition;
        }
    }
}
