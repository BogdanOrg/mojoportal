﻿<%@ Page Language="C#" AutoEventWireup="false" MasterPageFile="~/App_MasterPages/DialogMaster.Master" CodeBehind="CommentsDialog.aspx.cs" Inherits="mojoPortal.Features.UI.Comments.CommentsDialog" %>

<asp:Content ContentPlaceHolderID="phHead" ID="HeadContent" runat="server" />
<asp:Content ContentPlaceHolderID="phMain" ID="MainContent" runat="server">
	<portal:CommentEditor ID="commentEditor" runat="server" />
</asp:Content>
