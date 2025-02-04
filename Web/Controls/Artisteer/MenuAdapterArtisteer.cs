﻿/// Originally from Microsoft, Sample released under 
/// MS Permissive License 
/// http://www.microsoft.com/resources/sharedsource/licensingbasics/permissivelicense.mspx
/// (see license-ms-permissive.txt in the root of the solution)
/// 
/// Original source urls:
/// http://www.asp.net/cssadapters/
/// http://www.asp.net/CSSAdapters/WhitePaper.aspx
/// 
/// 
/// 
/// with modifications by 
/// Last Modified:      2010-08-24
/// added logic to use a different class for selected items

using System;
using System.IO;
using System.Web;
using System.Web.Configuration;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Web.UI.WebControls.Adapters;
using System.Web.UI.HtmlControls;
using mojoPortal.Web.UI;

namespace mojoPortal.Web
{
    /// <summary>
    /// 2008-04-23 added this version to render 3 spans inside the menu link
    /// for hanging css images
    /// 
    /// </summary>
    public class MenuAdapterArtisteer : System.Web.UI.WebControls.Adapters.MenuAdapter
    {
        private bool useMenuTooltipForCustomCss = false;

        private WebControlAdapterExtender _extender = null;
        private WebControlAdapterExtender Extender
        {
            get
            {
                if (((_extender == null) && (Control != null)) ||
                    ((_extender != null) && (Control != _extender.AdaptedControl)))
                {
                    
                    _extender = new WebControlAdapterExtender(Control);
                }

                System.Diagnostics.Debug.Assert(_extender != null, "CSS Friendly adapters internal error", "Null extender instance");
                return _extender;
            }
        }


        protected override void OnInit(EventArgs e)
        {
            base.OnInit(e);

            if (Extender.AdapterEnabled)
            {
                RegisterScripts();
            }

        }

        protected override void OnLoad(EventArgs e)
        {
            base.OnLoad(e);

            mojoMenuArtisteer artMenu = Control as mojoMenuArtisteer;
            if (artMenu != null) { useMenuTooltipForCustomCss = artMenu.UseMenuTooltipForCustomCss; }
        }


        private void RegisterScripts()
        {
            Extender.RegisterScripts();
            //string folderPath = WebConfigurationManager.AppSettings.Get("CSSFriendly-JavaScript-Path");
            //if (String.IsNullOrEmpty(folderPath))
            //{
            //    folderPath = "~/ClientScript";
            //}
            ////string filePath = folderPath.EndsWith("/") ? folderPath + "MenuAdapter.js" : folderPath + "/MenuAdapter.js";
            ////Page.ClientScript.RegisterClientScriptInclude(GetType(), GetType().ToString(), Page.ResolveUrl(filePath));
            //string filePath = folderPath.EndsWith("/") ? folderPath + "mojocombined.js" : folderPath + "/mojocombined.js";
            //Page.ClientScript.RegisterClientScriptInclude(typeof(Page), "mojocombined", Page.ResolveUrl(filePath));
        }

        protected override void RenderBeginTag(HtmlTextWriter writer)
        {
            if (Extender.AdapterEnabled)
            {
                Extender.RenderBeginTag(writer, "AspNet-Menu-" + Control.Orientation.ToString());
            }
            else
            {
                base.RenderBeginTag(writer);
            }
        }

        protected override void RenderEndTag(HtmlTextWriter writer)
        {
            if (Extender.AdapterEnabled)
            {
                Extender.RenderEndTag(writer);
            }
            else
            {
                base.RenderEndTag(writer);
            }
        }

        protected override void RenderContents(HtmlTextWriter writer)
        {
            if (Extender.AdapterEnabled)
            {
                writer.Indent++;
                BuildItems(Control.Items, true, writer);
                writer.Indent--;
                writer.WriteLine();
            }
            else
            {
                base.RenderContents(writer);
            }
        }


        private void BuildItems(MenuItemCollection items, bool isRoot, HtmlTextWriter writer)
        {
            //useMenuTooltipForCustomCss = WebConfigSettings.UseMenuTooltipForCustomCss;

            if (items.Count > 0)
            {

                writer.WriteLine();

                writer.WriteBeginTag("ul");
                if (isRoot)
                {
                    writer.WriteAttribute("class", "art-menu");
                }
                writer.Write(HtmlTextWriter.TagRightChar);
                writer.Indent++;

                foreach (MenuItem item in items)
                {
                    BuildItem(item, writer);
                }

                writer.Indent--;
                writer.WriteLine();
                writer.WriteEndTag("ul");
            }
        }



        private void BuildItem(MenuItem item, HtmlTextWriter writer)
        {
            Menu menu = Control as Menu;
            if ((menu != null) && (item != null) && (writer != null))
            {
                writer.WriteLine();
                writer.WriteBeginTag("li");

                //string theClass = (item.ChildItems.Count > 0) ? "AspNet-Menu-WithChildren" : "AspNet-Menu-Leaf";
                //string theClass = string.Empty;

                string theClass = GetSelectStatusClass(item);
                if (!String.IsNullOrEmpty(theClass))
                {
                    //theClass += " " + selectedStatusClass;
                    writer.WriteAttribute("class", theClass);
                }
               

                writer.Write(HtmlTextWriter.TagRightChar);
                writer.Indent++;
                writer.WriteLine();

                if (((item.Depth < menu.StaticDisplayLevels) && (menu.StaticItemTemplate != null)) ||
                    ((item.Depth >= menu.StaticDisplayLevels) && (menu.DynamicItemTemplate != null)))
                {
                    writer.WriteBeginTag("div");
                    writer.WriteAttribute("class", GetItemClass(menu, item));
                    writer.Write(HtmlTextWriter.TagRightChar);
                    writer.Indent++;
                    writer.WriteLine();

                    MenuItemTemplateContainer container = new MenuItemTemplateContainer(menu.Items.IndexOf(item), item);
                    if ((item.Depth < menu.StaticDisplayLevels) && (menu.StaticItemTemplate != null))
                    {
                        menu.StaticItemTemplate.InstantiateIn(container);
                    }
                    else
                    {
                        menu.DynamicItemTemplate.InstantiateIn(container);
                    }
                    container.DataBind();
                    container.RenderControl(writer);

                    writer.Indent--;
                    writer.WriteLine();
                    writer.WriteEndTag("div");
                }
                else
                {
                    if (IsLink(item))
                    {
                        writer.WriteBeginTag("a");
                        if (!String.IsNullOrEmpty(item.NavigateUrl))
                        {
                            //writer.WriteAttribute("href", Page.Server.HtmlEncode(menu.ResolveClientUrl(item.NavigateUrl)));
                            writer.WriteAttribute("href", menu.ResolveUrl(item.NavigateUrl));
                        }
                        else
                        {
                            writer.WriteAttribute("href", Page.ClientScript.GetPostBackClientHyperlink(menu, "b" + item.ValuePath.Replace(menu.PathSeparator.ToString(), "\\"), true));
                        }

                        //if (!String.IsNullOrEmpty(theClass))
                        //{
                            
                        //    writer.WriteAttribute("class", theClass);
                        //}

                        writer.WriteAttribute("class", GetItemClass(menu, item));
                        WebControlAdapterExtender.WriteTargetAttribute(writer, item.Target);

                        //we are using tooltip to store a custom css class not a tooltip
                        if (!useMenuTooltipForCustomCss)
                        {
                            if (!String.IsNullOrEmpty(item.ToolTip))
                            {
                                writer.WriteAttribute("title", item.ToolTip);
                            }
                            else if (!String.IsNullOrEmpty(menu.ToolTip))
                            {
                                writer.WriteAttribute("title", menu.ToolTip);
                            }
                        }
                        writer.Write(HtmlTextWriter.TagRightChar);
                        writer.Indent++;
                        writer.WriteLine();
                    }
                    else
                    {
                        writer.WriteBeginTag("span");
                        writer.WriteAttribute("class", GetItemClass(menu, item));
                        writer.Write(HtmlTextWriter.TagRightChar);
                        writer.Indent++;
                        writer.WriteLine();
                    }

                    //if (!String.IsNullOrEmpty(item.ImageUrl))
                    //{
                    //    writer.WriteBeginTag("img");
                    //    writer.WriteAttribute("src", menu.ResolveClientUrl(item.ImageUrl));
                    //    writer.WriteAttribute("alt", !String.IsNullOrEmpty(item.ToolTip) ? item.ToolTip : (!String.IsNullOrEmpty(menu.ToolTip) ? menu.ToolTip : item.Text));
                    //    writer.Write(HtmlTextWriter.SelfClosingTagEnd);
                    //    writer.Write(HtmlTextWriter.SpaceChar);
                    //}

                    //writer.WriteFullBeginTag("span");

                    writer.WriteBeginTag("span");
                    writer.WriteAttribute("class", "l");
                    writer.Write(HtmlTextWriter.TagRightChar);
                    writer.WriteEndTag("span");

                    writer.WriteBeginTag("span");
                    writer.WriteAttribute("class", "r");
                    writer.Write(HtmlTextWriter.TagRightChar);
                    writer.WriteEndTag("span");

                    writer.WriteBeginTag("span");
                    writer.WriteAttribute("class", "t");
                    writer.Write(HtmlTextWriter.TagRightChar);

                    if (!String.IsNullOrEmpty(item.ImageUrl))
                    {
                        writer.WriteBeginTag("img");
                        writer.WriteAttribute("src", menu.ResolveClientUrl(item.ImageUrl));
                        writer.WriteAttribute("alt", !String.IsNullOrEmpty(item.ToolTip) ? item.ToolTip : (!String.IsNullOrEmpty(menu.ToolTip) ? menu.ToolTip : item.Text));
                        writer.Write(HtmlTextWriter.SelfClosingTagEnd);
                        //writer.Write(HtmlTextWriter.SpaceChar);
                    }

                    writer.Write(item.Text);
                    writer.WriteEndTag("span");

                    

                    if (IsLink(item))
                    {
                        writer.Indent--;
                        writer.WriteEndTag("a");
                    }
                    else
                    {
                        writer.Indent--;
                        writer.WriteEndTag("span");
                    }

                }

                if ((item.ChildItems != null) && (item.ChildItems.Count > 0))
                {
                    BuildItems(item.ChildItems, false, writer);
                }

                writer.Indent--;
                writer.WriteLine();
                writer.WriteEndTag("li");
            }
        }

        private bool IsLink(MenuItem item)
        {
            //if ((item != null) && (!item.Selectable)) { return false; }
            return (item != null) && item.Enabled && ((!String.IsNullOrEmpty(item.NavigateUrl)) || item.Selectable);
        }

        private string GetItemClass(Menu menu, MenuItem item)
        {
            string value = string.Empty;
            if (item != null)
            {
                //if (((item.Depth < menu.StaticDisplayLevels) && (menu.StaticItemTemplate != null)) ||
                //    ((item.Depth >= menu.StaticDisplayLevels) && (menu.DynamicItemTemplate != null)))
                //{
                //    value = "AspNet-Menu-Template";
                //}
                //else if (IsLink(item))
                //{
                //    //value = "AspNet-Menu-Link";
                //    value = "AspNet-Menu";
                //}
                string selectedStatusClass = GetSelectStatusClass(item);
                if (!String.IsNullOrEmpty(selectedStatusClass))
                {
                    value += " " + selectedStatusClass;
                }
                if (!item.Selectable) { value += " unclickable"; }

                //this unfortuantely does not work item.DataItem is always null at this point after databainding
                //mojoSiteMapNode mapNode = item.DataItem as mojoSiteMapNode;
                //if((mapNode != null)&&(mapNode.MenuCssClass.Length > 0))
                //{
                //    value += " " + mapNode.MenuCssClass;
                //}
                if ((useMenuTooltipForCustomCss) &&(item.ToolTip.Length > 0))
                {
                    value += " " + item.ToolTip; //we are using tooltip to store a custom css class
                }
            }

            
            return value;
        }

        private string GetSelectStatusClass(MenuItem item)
        {
            string value;
            if (item.Selected)
            {
                //value += " AspNet-Menu-Selected";
                if (item.ChildItems.Count > 0)
                {
                    value = "active";
                }
                else
                {
                    value = "active";
                }
            }
            else if (IsChildItemSelected(item))
            {
                // top if logic added by 
                // so the topmost item is highlighted if
                // a child or grandchild is the current page
                if (item.Parent == null)
                {
                    value = " active";
                }
                else
                {
                    value = " active";
                }
            }
            //else if (IsParentItemSelected(item))
            //{
            //    value = " AspNet-Menu-ParentSelected";
            //}
            else
            {
                value = string.Empty;
            }

            

            return value;
        }

        private bool IsChildItemSelected(MenuItem item)
        {
            bool bRet = false;

            if ((item != null) && (item.ChildItems != null))
            {
                bRet = IsChildItemSelected(item.ChildItems);
            }

            return bRet;
        }


        private bool IsChildItemSelected(MenuItemCollection items)
        {
            bool bRet = false;

            if (items != null)
            {
                foreach (MenuItem item in items)
                {
                    if (item.Selected || IsChildItemSelected(item.ChildItems))
                    {
                        bRet = true;
                        break;
                    }
                }
            }

            return bRet;
        }

        private bool IsParentItemSelected(MenuItem item)
        {
            bool bRet = false;

            if ((item != null) && (item.Parent != null))
            {
                if (item.Parent.Selected)
                {
                    bRet = true;
                }
                else
                {
                    bRet = IsParentItemSelected(item.Parent);
                }
            }

            return bRet;
        }

    }

}
