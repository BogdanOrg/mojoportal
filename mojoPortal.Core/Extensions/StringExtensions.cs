﻿using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using mojoPortal.Core.Helpers;

namespace mojoPortal.Core.Extensions;

public static class StringExtensions
{
	public static string ToInvariantString(this int i, string format = null)
	{
		if (format is null)
		{
			return i.ToString(CultureInfo.InvariantCulture);
		}
		return i.ToString(format, CultureInfo.InvariantCulture);
	}

	public static string ToInvariantString(this float i, string format = null)
	{
		if (format is null)
		{
			return i.ToString(CultureInfo.InvariantCulture);
		}
		return i.ToString(format, CultureInfo.InvariantCulture);
	}

	public static string ToInvariantString(this decimal i, string format = null)
	{
		if (format is null)
		{
			return i.ToString(CultureInfo.InvariantCulture);
		}
		return i.ToString(format, CultureInfo.InvariantCulture);
	}

	public static bool ContainsCaseInsensitive(this string source, string value)
	{
		int results = source.IndexOf(value, StringComparison.CurrentCultureIgnoreCase);
		return results != -1;
	}

	public static bool IsCaseInsensitiveMatch(this string str1, string str2)
	{
		return string.Equals(str1, str2, StringComparison.InvariantCultureIgnoreCase);

	}

	public static string ToSerialDate(this string s)
	{
		if (s.Length == 8)
		{
			return s.Substring(0, 4) + "-" + s.Substring(4, 2) + "-" + s.Substring(6, 2);
		}
		return s;
	}

	public static string HtmlEscapeQuotes(this string s)
	{
		if (string.IsNullOrWhiteSpace(s)) { return s; }

		return s.Replace("'", "&#39;").Replace("\"", "&#34;");
	}

	public static string RemoveCDataTags(this string s)
	{
		if (string.IsNullOrWhiteSpace(s)) { return s; }

		return s.Replace("<![CDATA[", string.Empty).Replace("]]>", string.Empty);
	}

	public static string CsvEscapeQuotes(this string s)
	{
		if (string.IsNullOrWhiteSpace(s)) { return s; }

		return s.Replace("\"", "\"\"");
	}

	public static string RemoveAngleBrackets(this string s)
	{
		if (string.IsNullOrWhiteSpace(s)) { return s; }

		return s.Replace("<", string.Empty).Replace(">", string.Empty);
	}

	public static string Coalesce(this string s, string alt)
	{
		if (string.IsNullOrWhiteSpace(s)) { return alt; }
		return s;
	}

	/// <summary>
	/// Converts a unicode string into its closest ascii equivalent
	/// </summary>
	/// <param name="s"></param>
	/// <returns></returns>
	public static string ToAscii(this string s)
	{
		if (string.IsNullOrWhiteSpace(s))
		{
			return s;
		}

		try
		{
			string normalized = s.Normalize(NormalizationForm.FormKD);

			Encoding ascii = Encoding.GetEncoding(
				  "us-ascii",
				  new EncoderReplacementFallback(string.Empty),
				  new DecoderReplacementFallback(string.Empty));

			byte[] encodedBytes = new byte[ascii.GetByteCount(normalized)];
			int numberOfEncodedBytes = ascii.GetBytes(normalized, 0, normalized.Length,
			encodedBytes, 0);

			return ascii.GetString(encodedBytes);
		}
		catch
		{
			return s;
		}
	}

	/// <summary>
	/// Converts a unicode string into its closest ascii equivalent.
	/// If the ascii encode string length is less than or equal to 1 returns the original string
	/// as this means the string is probably in a language with no ascii equivalents
	/// </summary>
	/// <param name="s"></param>
	/// <returns></returns>
	public static string ToAsciiIfPossible(this string s)
	{
		if (string.IsNullOrWhiteSpace(s)) { return s; }

		//http://www.mojoportal.com/Forums/Thread.aspx?thread=8974&mid=34&pageid=5&ItemID=9
		s = s.Replace("æ", "ae");
		s = s.Replace("Æ", "ae");
		s = s.Replace("å", "aa");
		s = s.Replace("Å", "aa");

		// based on:
		//http://www.mojoportal.com/Forums/Thread.aspx?thread=9176&mid=34&pageid=5&ItemID=9&pagenumber=1#post38114

		int len = s.Length;
		var sb = new StringBuilder(len);
		char c;

		for (int i = 0; i < len; i++)
		{
			c = s[i];

			if ((int)c >= 128)
			{
				sb.Append(StringHelper.RemapInternationalCharToAscii(c));

			}
			else
			{
				sb.Append(c);
			}
		}

		return sb.ToString();
	}

	public static string RemoveNonNumeric(this string s)
	{
		if (string.IsNullOrWhiteSpace(s))
		{
			return s;
		}

		char[] result = new char[s.Length];
		int resultIndex = 0;
		foreach (char c in s)
		{
			if (char.IsNumber(c))
				result[resultIndex++] = c;
		}
		if (0 == resultIndex)
		{
			s = string.Empty;
		}
		else if (result.Length != resultIndex)
		{
			s = new string(result, 0, resultIndex);
		}

		return s;
	}

	public static string RemoveLineBreaks(this string s, string Replacement = "")
	{
		if (string.IsNullOrWhiteSpace(s)) { return s; }

		return s.Replace("\r\n", Replacement).Replace("\n", Replacement).Replace("\r", Replacement);
	}

	/// <summary>
	/// Removes Sequential Spaces in a string. RegEx isn't necessarily faster.
	/// </summary>
	/// <param name="s"></param>
	/// <param name="UseRegEx"></param>
	/// <returns></returns>
	public static string RemoveMultipleSpaces(this string s, bool UseRegEx = false)
	{
		if (string.IsNullOrWhiteSpace(s)) { return s; }

		if (UseRegEx)
		{
			var regex = new Regex("[ ]{2,}", RegexOptions.None);
			return regex.Replace(s, " ");
		}

		var sb = new StringBuilder(s.Length);

		int i = 0;
		foreach (char c in s)
		{
			if (c != ' ' || i == 0 || s[i - 1] != ' ')
			{
				sb.Append(c);
			}
			i++;
		}
		return sb.ToString();
	}

	public static string EscapeXml(this string s)
	{
		string xml = s;
		if (!string.IsNullOrWhiteSpace(xml))
		{
			// replace literal values with entities
			xml = xml.Replace("&", "&amp;");
			xml = xml.Replace("&lt;", "&lt;");
			xml = xml.Replace("&gt;", "&gt;");
			xml = xml.Replace("\"", "&quot;");
			xml = xml.Replace("'", "&apos;");
		}
		return xml;
	}

	public static string UnescapeXml(this string s)
	{
		string unxml = s;
		if (!string.IsNullOrWhiteSpace(unxml))
		{
			// replace entities with literal values
			unxml = unxml.Replace("&apos;", "'");
			unxml = unxml.Replace("&quot;", "\"");
			unxml = unxml.Replace("&gt;", "&gt;");
			unxml = unxml.Replace("&lt;", "&lt;");
			unxml = unxml.Replace("&amp;", "&");
		}
		return unxml;
	}

	public static List<string> SplitOnChar(this string s, char c)
	{
		var list = new List<string>();
		if (string.IsNullOrWhiteSpace(s))
		{
			return list;
		}

		string[] a = s.Split(c);
		foreach (string item in a)
		{
			if (!string.IsNullOrWhiteSpace(item))
			{
				list.Add(item);
			}
		}

		return list;
	}

	public static List<string> SplitOnCharAndTrim(this string s, char c)
	{
		var list = new List<string>();
		if (string.IsNullOrWhiteSpace(s))
		{
			return list;
		}

		string[] a = s.Split(c);
		foreach (string item in a)
		{
			if (!string.IsNullOrWhiteSpace(item))
			{
				list.Add(item.Trim());
			}
		}

		return list;
	}

	public static List<int> SplitIntStringOnCharAndTrim(this string s, char c)
	{
		var list = new List<int>();
		if (string.IsNullOrWhiteSpace(s))
		{
			return list;
		}

		string[] a = s.Split(c);
		foreach (string item in a)
		{
			if (!string.IsNullOrWhiteSpace(item))
			{
				list.Add(Convert.ToInt32(item.Trim()));
			}
		}

		return list;
	}

	public static List<string> SplitOnNewLineAndTrim(this string s)
	{
		var list = new List<string>();
		if (string.IsNullOrWhiteSpace(s))
		{
			return list;
		}

		string[] a = s.Split(new[] { "\r\n", "\r", "\n" }, StringSplitOptions.RemoveEmptyEntries);

		foreach (string b in a)
		{
			if (!string.IsNullOrWhiteSpace(b))
			{
				list.Add(b.Trim());
			}
		}
		return list;
	}

	/// <summary>
	/// Determines if a string is in an array of strings.
	/// </summary>
	/// <returns>bool</returns>
	/// <example>
	/// string color = "blue";
	/// string[] colors = {"blue", "green", "red"};
	/// bool validColor = false;
	/// validColor = color.IsIn(colors);
	/// </example>
	public static bool IsIn<T>(this T source, params T[] values)
	{
		return values.Contains(source);
	}

	public static List<string> SplitOnPipes(this string s)
	{
		var list = new List<string>();

		if (string.IsNullOrWhiteSpace(s))
		{
			return list;
		}

		string[] a = s.Split('|');
		foreach (string item in a)
		{
			if (!string.IsNullOrWhiteSpace(item))
			{
				list.Add(item);
			}
		}

		return list;
	}
}