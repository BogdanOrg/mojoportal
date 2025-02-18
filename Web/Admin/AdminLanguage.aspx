﻿<%@ Page Language="C#" AutoEventWireup="false" MasterPageFile="~/App_MasterPages/layout.Master"
	CodeBehind="AdminLanguage.aspx.cs" Inherits="mojoPortal.Web.AdminUI.AdminLanguagePage" %>

<asp:Content ContentPlaceHolderID="leftContent" ID="MPLeftPane" runat="server" />
<asp:Content ContentPlaceHolderID="mainContent" ID="MPContent" runat="server">
	<portal:AdminCrumbContainer ID="pnlAdminCrumbs" runat="server" CssClass="breadcrumbs">
		<asp:HyperLink ID="lnkAdminMenu" runat="server" NavigateUrl="~/Admin/AdminMenu.aspx" /><portal:AdminCrumbSeparator runat="server" Text="&nbsp;&gt;" EnableViewState="false" />
        <asp:HyperLink ID="lnkCoreData" runat="server" NavigateUrl="~/Admin/AdminMenu.aspx" /><portal:AdminCrumbSeparator runat="server" Text="&nbsp;&gt;" EnableViewState="false" />
        <asp:HyperLink ID="lnkCurrentPage" runat="server" CssClass="selectedcrumb" />
	</portal:AdminCrumbContainer>
	<portal:OuterWrapperPanel ID="pnlOuterWrap" runat="server">
		<portal:InnerWrapperPanel ID="pnlInnerWrap" runat="server" CssClass="panelwrapper admin adminlanguage">
			<portal:HeadingControl ID="heading" runat="server" />
			<portal:OuterBodyPanel ID="pnlOuterBody" runat="server">
				<portal:InnerBodyPanel ID="pnlInnerBody" runat="server" CssClass="modulecontent">
					<mp:mojoGridView ID="grdLanguage" runat="server" AllowPaging="false" AllowSorting="false"
						AutoGenerateColumns="false" DataKeyNames="Guid">
						<Columns>
							<asp:TemplateField>
								<ItemTemplate>
									<asp:Button ID="btnEdit" runat="server" CommandName="Edit" CssClass="buttonlink" Tezt='<%# Resources.Resource.LanguageGridEditButton %>' />
								</ItemTemplate>
								<EditItemTemplate>
									<asp:Button ID="btnGridUpdate" runat="server" Text='<%# Resources.Resource.LanguageGridUpdateButton %>'
										CommandName="Update" />
									<asp:Button ID="btnGridDelete" runat="server" Text='<%# Resources.Resource.LanguageGridDeleteButton %>'
										CommandName="Delete" />
									<asp:Button ID="btnGridCancel" runat="server" Text='<%# Resources.Resource.LanguageGridCancelButton %>'
										CommandName="Cancel" />
								</EditItemTemplate>
							</asp:TemplateField>
							<asp:TemplateField>
								<ItemTemplate>
									<%# Eval("Name") %>
								</ItemTemplate>
								<EditItemTemplate>
									<asp:TextBox ID="txtName" Columns="20" Text='<%# Eval("Name") %>' runat="server"
										MaxLength="255" />
								</EditItemTemplate>
							</asp:TemplateField>
							<asp:TemplateField>
								<ItemTemplate>
									<%# Eval("Code") %>
								</ItemTemplate>
								<EditItemTemplate>
									<asp:TextBox ID="txtCode" Columns="20" Text='<%# Eval("Code") %>' runat="server"
										MaxLength="2" />
								</EditItemTemplate>
							</asp:TemplateField>
							<asp:TemplateField>
								<ItemTemplate>
									<%# Eval("Sort") %>
								</ItemTemplate>
								<EditItemTemplate>
									<asp:TextBox ID="txtSort" Columns="20" Text='<%# Eval("Sort") %>' runat="server"
										MaxLength="4" />
								</EditItemTemplate>
							</asp:TemplateField>
						</Columns>
					</mp:mojoGridView>
					<div class="settingrow">
						<portal:mojoButton ID="btnAddNew" runat="server" />
					</div>
					<portal:mojoCutePager ID="pgrLanguage" runat="server" />
				</portal:InnerBodyPanel>
			</portal:OuterBodyPanel>
		</portal:InnerWrapperPanel>
	</portal:OuterWrapperPanel>
</asp:Content>
<asp:Content ContentPlaceHolderID="rightContent" ID="MPRightPane" runat="server" />
<asp:Content ContentPlaceHolderID="pageEditContent" ID="MPPageEdit" runat="server" />
