// Author:             
// Created:            2006-12-02
// Last Modified:      2008-01-27

using System;

namespace mojoPortal.Business.Statistics
{
	/// <summary>
	/// 
	/// </summary>
	public class MembershipStatistics
	{
		#region Constructors

		public MembershipStatistics(SiteSettings siteSettings, DateTime todaysDate)
		{
			GetStatistics(siteSettings, todaysDate);
		}

		#endregion

		#region Private Properties

		private int siteID = -1;
		private string siteName = string.Empty;

		private int totalUsers;
		private int newUsersToday;
		private int newUsersYesterday;
		private string newestUser = string.Empty;

		#endregion

		#region Public Properties

		public int SiteId
		{
			get { return siteID; }
		}

		public string SiteName
		{
			get { return siteName; }
		}

		public int TotalUsers
		{
			get { return totalUsers; }
		}

		public int NewUsersToday
		{
			get { return newUsersToday; }
		}

		public int NewUsersYesterday
		{
			get { return newUsersYesterday; }
		}

		public string NewestUser
		{
			get { return newestUser; }
		}


		#endregion

		#region Private Methods

		private void GetStatistics(SiteSettings siteSettings, DateTime today)
		{
			if (siteSettings != null)
			{
				siteID = siteSettings.SiteId;
				siteName = siteSettings.SiteName;

				totalUsers = SiteUser.UserCount(siteID);
				SiteUser newestSiteUser = SiteUser.GetNewestUser(siteSettings);
				newestUser = newestSiteUser.Name;
				//DateTime today = DateTime.Today.ToUniversalTime().AddHours(DateTimeHelper.GetPreferredGMTOffset());
				newUsersToday = SiteUser.CountUsersByRegistrationDateRange(siteID, today, today.AddDays(1));
				newUsersYesterday = SiteUser.CountUsersByRegistrationDateRange(siteID, today.AddDays(-1), today);

			}

		}

		#endregion

	}
}
