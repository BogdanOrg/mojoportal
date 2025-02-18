<%@ Page Language="C#" AutoEventWireup="false" MasterPageFile="~/App_MasterPages/layout.Master" CodeBehind="LetterArchive.aspx.cs" Inherits="mojoPortal.Web.ELetterUI.LetterArchivePage" %>

<asp:Content ContentPlaceHolderID="leftContent" ID="MPLeftPane" runat="server" />
<asp:Content ContentPlaceHolderID="mainContent" ID="MPContent" runat="server">
	<portal:AdminCrumbContainer ID="pnlAdminCrumbs" runat="server" CssClass="breadcrumbs">
		<asp:HyperLink ID="lnkAdminMenu" runat="server" NavigateUrl="~/Admin/AdminMenu.aspx" CssClass="unselectedcrumb" /><portal:AdminCrumbSeparator ID="litLinkSeparator1" runat="server" Text="&nbsp;&gt;" EnableViewState="false" />
		<asp:HyperLink ID="lnkLetterAdmin" runat="server" CssClass="unselectedcrumb" /><portal:AdminCrumbSeparator ID="AdminCrumbSeparator1" runat="server" Text="&nbsp;&gt;" EnableViewState="false" />
		<asp:HyperLink ID="lnkThisPage" runat="server" CssClass="selectedcrumb" />
	</portal:AdminCrumbContainer>
	<portal:OuterWrapperPanel ID="pnlOuterWrap" runat="server">
		<portal:InnerWrapperPanel ID="pnlInnerWrap" runat="server" CssClass="panelwrapper newsletteradmin">
			<portal:HeadingControl ID="heading" runat="server" />
			<portal:OuterBodyPanel ID="pnlOuterBody" runat="server">
				<portal:InnerBodyPanel ID="pnlInnerBody" runat="server" CssClass="modulecontent">
					<mp:mojoGridView ID="grdLetter" runat="server"
						AllowPaging="false"
						AllowSorting="false"
						AutoGenerateColumns="false"
						CssClass=""
						DataKeyNames="LetterGuid">
						<Columns>
							<asp:TemplateField>
								<ItemTemplate>
									<asp:HyperLink ID="lnkEdit" runat="server"
										Text='<%# Resources.Resource.NewsletterEditLink %>' ToolTip='<%# Eval("Subject") %>'
										NavigateUrl='<%# SiteRoot + "/eletter/LetterEdit.aspx?l=" + Eval("LetterInfoGuid").ToString() + "&letter=" + Eval("LetterGuid").ToString() %>'></asp:HyperLink>
									<asp:HyperLink ID="lnkLetterView" runat="server" CssClass="cblink" NavigateUrl='<%# SiteRoot + "/eletter/LetterView.aspx?l=" + Eval("LetterInfoGuid") + "&letter=" + Eval("LetterGuid") %>' Text='<%# Resources.Resource.NewsletterViewLink %>' ToolTip='<%# Eval("Subject") %>' />
									<%# Eval("Subject") %>
								</ItemTemplate>
							</asp:TemplateField>
							<asp:TemplateField>
								<ItemTemplate>
									<%# DateTimeHelper.Format(Convert.ToDateTime(Eval("SendClickedUTC")), timeZone, "g", timeOffset) %>
								</ItemTemplate>
							</asp:TemplateField>
							<asp:TemplateField>
								<ItemTemplate>
									<%# DateTimeHelper.Format(Convert.ToDateTime(Eval("SendCompleteUTC")), timeZone, "g", timeOffset) %>
								</ItemTemplate>
							</asp:TemplateField>
							<asp:TemplateField>
								<ItemTemplate>
									<asp:HyperLink ID="lnkView" runat="server"
										Text='<%# Eval("SendCount") %>' ToolTip='<%# Resources.Resource.NewsletterViewSendLogToolTip %>'
										NavigateUrl='<%# SiteRoot + "/eletter/SendLog.aspx?letter=" + Eval("LetterGuid").ToString() %>'></asp:HyperLink>
								</ItemTemplate>
							</asp:TemplateField>
						</Columns>
						<EmptyDataTemplate>
							<p class="nodata">
								<asp:Literal ID="litempty" runat="server" Text="<%$ Resources:Resource, GridViewNoData %>" />
							</p>
						</EmptyDataTemplate>
					</mp:mojoGridView>
					<portal:mojoCutePager ID="pgrLetter" runat="server" />
					<div class="settingrow">
						<portal:mojoButton ID="btnPurgeSendLogs" runat="server" />
					</div>

				</portal:InnerBodyPanel>
			</portal:OuterBodyPanel>
		</portal:InnerWrapperPanel>
	</portal:OuterWrapperPanel>
</asp:Content>
<asp:Content ContentPlaceHolderID="rightContent" ID="MPRightPane" runat="server" />
<asp:Content ContentPlaceHolderID="pageEditContent" ID="MPPageEdit" runat="server" />
