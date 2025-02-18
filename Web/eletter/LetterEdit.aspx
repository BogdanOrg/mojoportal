<%@ Page Language="C#" AutoEventWireup="false" MasterPageFile="~/App_MasterPages/layout.Master"
	CodeBehind="LetterEdit.aspx.cs" Inherits="mojoPortal.Web.ELetterUI.LetterEditPage" %>

<asp:Content ContentPlaceHolderID="leftContent" ID="MPLeftPane" runat="server" />
<asp:Content ContentPlaceHolderID="mainContent" ID="MPContent" runat="server">
	<portal:AdminCrumbContainer ID="pnlAdminCrumbs" runat="server" CssClass="breadcrumbs">
		<asp:HyperLink ID="lnkAdminMenu" runat="server" NavigateUrl="~/Admin/AdminMenu.aspx" CssClass="unselectedcrumb" /><portal:AdminCrumbSeparator ID="litLinkSeparator1" runat="server" Text="&nbsp;&gt;" EnableViewState="false" />
		<asp:HyperLink ID="lnkLetterAdmin" runat="server" CssClass="unselectedcrumb" /><portal:AdminCrumbSeparator ID="AdminCrumbSeparator1" runat="server" Text="&nbsp;&gt;" EnableViewState="false" />
		<asp:HyperLink ID="lnkDraftList" runat="server" CssClass="selectedcrumb" />
	</portal:AdminCrumbContainer>
	<portal:OuterWrapperPanel ID="pnlOuterWrap" runat="server">

		<portal:InnerWrapperPanel ID="pnlInnerWrap" runat="server" CssClass="panelwrapper editpage newsletter">
			<portal:HeadingControl ID="heading" runat="server" />
			<portal:OuterBodyPanel ID="pnlOuterBody" runat="server" SkinID="admin">
				<portal:InnerBodyPanel ID="pnlInnerBody" runat="server" CssClass="modulecontent">
					<div class="settingrow">
						<mp:SiteLabel ID="lbl1" runat="server" CssClass="settinglabel" ConfigKey="NewsLetterSubjectLabel" />
						<asp:TextBox ID="txtSubject" runat="server" Columns="70" CssClass="forminput" />
						<asp:RequiredFieldValidator ID="reqSubject" ValidationGroup="newsletteredit" runat="server" CssClass="txterror" Display="Dynamic" ControlToValidate="txtSubject" />
					</div>
					<div class="settingrow">
						<mp:SiteLabel ID="SiteLabel35" runat="server" CssClass="settinglabel" ConfigKey="spacer" />
						<portal:mojoButton ID="btnSave" runat="server" />&nbsp;
						<portal:mojoButton ID="btnDelete" runat="server" CausesValidation="False" />&nbsp;
						<portal:mojoButton ID="btnSendToList" runat="server" />&nbsp;
						<portal:mojoHelpLink ID="MojoHelpLink2" runat="server" HelpKey="newsletter-general-help" />
						<portal:mojoLabel ID="lblErrorMessage" runat="server" CssClass="txterror warning" />
					</div>
					<div class="settingrow">
						<mp:SiteLabel ID="SiteLabel2" runat="server" CssClass="settinglabel" ConfigKey="spacer" />
						<portal:mojoButton ID="btnSendPreview" runat="server" Text="" CausesValidation="false" />&nbsp;
						<asp:TextBox ID="txtPreviewAddress" runat="server" CssClass="mediumtextbox" />
						<portal:mojoButton ID="btnGeneratePlainText" runat="server" />
					</div>
					<div class="settingrow">
						<mp:SiteLabel ID="SiteLabel1" runat="server" CssClass="settinglabel" ConfigKey="NewsLetterTemplatesLabel" />
						<asp:DropDownList ID="ddTemplates" runat="server" DataTextField="Title" DataValueField="Guid" />
						<portal:mojoButton ID="btnLoadTemplate" runat="server" />
					</div>
					<div class="settingrow">
						<mp:SiteLabel ID="SiteLabel3" runat="server" CssClass="settinglabel" ConfigKey="spacer" />
						<portal:mojoButton ID="btnSaveAsTemplate" runat="server" ValidationGroup="newtemplate" />
						<asp:TextBox ID="txtNewTemplateName" runat="server" CssClass="mediumtextbox" />
						<asp:RequiredFieldValidator ID="reqTemplateName" ValidationGroup="newtemplate" runat="server" CssClass="txterror" Display="Dynamic" ControlToValidate="txtNewTemplateName" />
						<asp:HyperLink ID="lnkManageTemplates" runat="server" />
					</div>
					<div id="divtabs" class="mojo-tabs">
						<ul>
							<li class="selected"><a href="#tabHtml">
								<asp:Literal ID="litHtmlTab" runat="server" EnableViewState="false" /></a></li>
							<li><a href="#tabPlainText">
								<asp:Literal ID="litPlainTextTab" runat="server" EnableViewState="false" /></a></li>
						</ul>
						<div id="tabHtml">
							<mpe:EditorControl ID="edContent" runat="server" />
						</div>
						<div id="tabPlainText">
							<asp:TextBox ID="txtPlainText" runat="server" TextMode="MultiLine" Width="100%" Height="800px" />
						</div>
					</div>
				</portal:InnerBodyPanel>
			</portal:OuterBodyPanel>
		</portal:InnerWrapperPanel>
	</portal:OuterWrapperPanel>
</asp:Content>
<asp:Content ContentPlaceHolderID="rightContent" ID="MPRightPane" runat="server" />
<asp:Content ContentPlaceHolderID="pageEditContent" ID="MPPageEdit" runat="server" />
