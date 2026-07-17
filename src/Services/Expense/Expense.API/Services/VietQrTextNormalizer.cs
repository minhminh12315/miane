using System.Globalization;
using System.Text;
using System.Text.RegularExpressions;

namespace Expense.API.Services;

public static partial class VietQrTextNormalizer
{
    public static string NormalizeAccountName(string value)
    {
        var normalized = RemoveVietnameseMarks(value).ToUpperInvariant();
        normalized = UnsupportedAccountNameCharactersRegex().Replace(normalized, " ");
        return CollapseSpaces(normalized, 50);
    }

    public static string NormalizeAddInfo(string? value)
    {
        var normalized = RemoveVietnameseMarks(value ?? "MIANE").ToUpperInvariant();
        normalized = UnsupportedAddInfoCharactersRegex().Replace(normalized, " ");
        normalized = CollapseSpaces(normalized, 25);
        return normalized.Length == 0 ? "MIANE" : normalized;
    }

    public static string DigitsOnly(string value) =>
        DigitsOnlyRegex().Replace(value, string.Empty);

    private static string RemoveVietnameseMarks(string value)
    {
        var formD = value.Trim().Normalize(NormalizationForm.FormD);
        var builder = new StringBuilder(formD.Length);
        foreach (var ch in formD)
        {
            var category = CharUnicodeInfo.GetUnicodeCategory(ch);
            if (category == UnicodeCategory.NonSpacingMark)
            {
                continue;
            }

            builder.Append(ch switch
            {
                'đ' => 'd',
                'Đ' => 'D',
                _ => ch
            });
        }

        return builder.ToString().Normalize(NormalizationForm.FormC);
    }

    private static string CollapseSpaces(string value, int maxLength)
    {
        var collapsed = MultipleSpacesRegex().Replace(value, " ").Trim();
        return collapsed.Length <= maxLength
            ? collapsed
            : collapsed[..maxLength].TrimEnd();
    }

    [GeneratedRegex("[^A-Z0-9 ]")]
    private static partial Regex UnsupportedAccountNameCharactersRegex();

    [GeneratedRegex("[^A-Z0-9 ]")]
    private static partial Regex UnsupportedAddInfoCharactersRegex();

    [GeneratedRegex("\\s+")]
    private static partial Regex MultipleSpacesRegex();

    [GeneratedRegex("\\D")]
    private static partial Regex DigitsOnlyRegex();
}
