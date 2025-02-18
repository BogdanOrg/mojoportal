﻿<%@ Control Language="C#" AutoEventWireup="true" CodeBehind="FeedLinksControl.ascx.cs" Inherits="mojoPortal.Web.BlogUI.FeedLinksControl" %>
<%@ Register Namespace="mojoPortal.Web.BlogUI" Assembly="mojoPortal.Features.UI" TagPrefix="blog" %>

<blog:BlogDisplaySettings ID="displaySettings" runat="server" />

<ul class="<%= displaySettings.CategoryListClass %> blog-feed-links" is>
	<li id="liRSS" runat="server" class="feedrsslinkitem">
		<asp:Literal ID="litRssLink" runat="server" />
	</li>
</ul>