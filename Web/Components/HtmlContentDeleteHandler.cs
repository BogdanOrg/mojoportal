﻿//  Author:                     
//  Created:                    2009-06-21
//	Last Modified:              2009-06-21
// 
// The use and distribution terms for this software are covered by the 
// Common Public License 1.0 (http://opensource.org/licenses/cpl.php)
// which can be found in the file CPL.TXT at the root of this distribution.
// By using this software in any fashion, you are agreeing to be bound by 
// the terms of this license.
//
// You must not remove this notice, or any other, from this software.

using System;
using System.Collections.Generic;
using System.Text;
using mojoPortal.Business;
using mojoPortal.Business.WebHelpers;

namespace mojoPortal.Web
{
    public class HtmlContentDeleteHandler : ContentDeleteHandlerProvider
    {
        public HtmlContentDeleteHandler()
        { }

        public override void DeleteContent(int moduleId, Guid moduleGuid)
        {
            ContentHistory.DeleteByContent(moduleGuid);
            ContentWorkflow.DeleteByModule(moduleGuid);
            HtmlRepository repository = new HtmlRepository();
            repository.DeleteByModule(moduleId);
            
        }

    }
}
