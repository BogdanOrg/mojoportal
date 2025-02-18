﻿using System;
using mojoPortal.Web;

namespace mojoPortal.Features.UI.BetterImageGallery;

public partial class BetterImageGalleryModule : SiteModuleControl
{
	protected override void OnInit(EventArgs e)
	{
		base.OnInit(e);
		Load += new EventHandler(Page_Load);
		EnableViewState = false;
	}

	protected virtual void Page_Load(object sender, EventArgs e)
	{
		gallery1.BigConfig = new BIGConfig(Settings);
		gallery1.ModuleId = ModuleId;
	}
}