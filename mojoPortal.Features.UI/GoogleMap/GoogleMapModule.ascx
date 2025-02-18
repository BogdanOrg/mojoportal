﻿<%@ Control Language="C#" AutoEventWireup="false" CodeBehind="GoogleMapModule.ascx.cs" Inherits="mojoPortal.Web.MapUI.GoogleMapModule" %>
<portal:OuterWrapperPanel ID="pnlOuterWrap" runat="server">

<portal:InnerWrapperPanel ID="pnlInnerWrap" runat="server" cssclass="panelwrapper GoogleMap">
<portal:ModuleTitleControl runat="server" id="TitleControl" />
<portal:OuterBodyPanel ID="pnlOuterBody" runat="server">
<portal:InnerBodyPanel ID="pnlInnerBody" runat="server" CssClass="modulecontent">
<portal:LocationMap ID="gmap" runat="server" EnableMapType="true" EnableZoom="true" ShowInfoWindow="true" EnableLocalSearch="true"></portal:LocationMap>
<asp:Literal ID="litCaption" runat="server" /><br />
</portal:InnerBodyPanel>
</portal:OuterBodyPanel>

</portal:InnerWrapperPanel>

</portal:OuterWrapperPanel>
