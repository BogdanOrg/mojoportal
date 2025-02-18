﻿using System;
using System.Text;
using mojoPortal.Web.Framework;
using mojoPortal.Business;
using mojoPortal.Business.WebHelpers;
using Resources;

namespace mojoPortal.Web.ELetterUI;

public partial class SendProgressPage : NonCmsBasePage
{
	private bool isSiteEditor = false;
	private LetterInfo letterInfo = null;
	private Letter letter = null;
	private Guid letterInfoGuid = Guid.Empty;
	private Guid letterGuid = Guid.Empty;
	private Guid taskGuid = Guid.Empty;

	protected void Page_Load(object sender, EventArgs e)
	{
		isSiteEditor = SiteUtils.UserIsSiteEditor();
		if ((!isSiteEditor) && (!WebUser.IsNewsletterAdmin))
		{
			SiteUtils.RedirectToAccessDeniedPage(this);
			return;
		}

		LoadParams();

		LoadSettings();
		PopulateLabels();
		PopulateControls();
		SetupScript();
	}

	private void PopulateControls()
	{
		if (letterInfo != null)
		{
			litLetterInfoTitle.Text = Server.HtmlEncode(letterInfo.Title);
		}

		if (letter != null)
		{
			litSubject.Text = Server.HtmlEncode(letter.Subject);
		}
	}

	private void SetupScript()
	{
		StringBuilder script = new StringBuilder();
		script.Append("\n<script type=\"text/javascript\">");

		script.Append("$('#" + pnlProgress.ClientID + "').progressbar({ value: 0 });");
		script.Append("$('#" + lnkSendLog.ClientID + "').hide(); ");
		script.Append("setTimeout(function(){updateProgress" + pnlProgress.ClientID + "();}, 500);");

		//function to check task status
		script.Append("function updateProgress" + pnlProgress.ClientID + "() {");
		script.Append("$.getJSON('" + SiteRoot + "/Services/TaskProgress.ashx?t=" + taskGuid.ToString() + "'");
		script.Append(",function(data){");
		script.Append("$('#" + pnlProgress.ClientID + "').progressbar('option','value',data.percentComplete);");
		script.Append("$('#" + pnlStatus.ClientID + "').text(data.status); ");

		script.Append("if(data.percentComplete < 100){");
		script.Append("setTimeout(function(){updateProgress" + pnlProgress.ClientID + "();}, 4000); ");
		script.Append("}");
		script.Append("else{");
		script.Append("$('#" + lnkSendLog.ClientID + "').show(); ");
		script.Append("}");
		//script.Append("alert(data.percentComplete);");
		script.Append("});");
		script.Append("}");
		script.Append("</script>");

		Page.ClientScript.RegisterStartupScript(
			GetType(),
			pnlProgress.UniqueID,
			script.ToString());
	}

	private void PopulateLabels()
	{
		Title = SiteUtils.FormatPageTitle(siteSettings, Resource.AdminMenuNewsletterAdminLabel);

		lnkAdminMenu.Text = Resource.AdminMenuLink;
		lnkAdminMenu.ToolTip = Resource.AdminMenuLink;
		lnkAdminMenu.NavigateUrl = SiteRoot + "/Admin/AdminMenu.aspx";


		lnkLetterAdmin.Text = Resource.NewsLetterAdministrationHeading;
		lnkLetterAdmin.ToolTip = Resource.NewsLetterAdministrationHeading;
		lnkLetterAdmin.NavigateUrl = SiteRoot + "/eletter/Admin.aspx";

		heading.Text = Resource.NewsletterProgressHeading;

		lnkSendLog.Text = Resource.NewsletterSendLogLink;
	}

	private void LoadSettings()
	{
		if (letterInfoGuid != Guid.Empty)
		{
			letterInfo = new LetterInfo(letterInfoGuid);
			if (letterInfo.LetterInfoGuid == Guid.Empty) { letterInfo = null; }
			if (letterInfo.SiteGuid != siteSettings.SiteGuid) { letterInfo = null; }
		}

		if (letterGuid != Guid.Empty)
		{
			letter = new Letter(letterGuid);
			if (letter.LetterGuid == Guid.Empty) { letter = null; }
			if (letter.LetterInfoGuid != letterInfoGuid) { letter = null; }
		}

		lnkSendLog.NavigateUrl = SiteRoot + "/eletter/SendLog.aspx?letter=" + letterGuid.ToString();

		lnkAdminMenu.Visible = WebUser.IsAdminOrContentAdmin;
		litLinkSeparator1.Visible = lnkAdminMenu.Visible;

		AddClassToBody("administration");
		AddClassToBody("lettersendprogress");
	}

	private void LoadParams()
	{
		letterInfoGuid = WebUtils.ParseGuidFromQueryString("l", letterInfoGuid);
		letterGuid = WebUtils.ParseGuidFromQueryString("letter", letterGuid);
		taskGuid = WebUtils.ParseGuidFromQueryString("t", taskGuid);
	}

	#region OnInit

	override protected void OnInit(EventArgs e)
	{
		base.OnInit(e);
		Load += new EventHandler(Page_Load);
	}

	#endregion
}