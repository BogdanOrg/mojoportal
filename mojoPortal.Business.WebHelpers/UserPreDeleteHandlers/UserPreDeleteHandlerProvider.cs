﻿//  Author:                     
//  Created:                    2012-07-09
//	Last Modified:              2012-07-09
// 
// The use and distribution terms for this software are covered by the 
// Common Public License 1.0 (http://opensource.org/licenses/cpl.php)
// which can be found in the file CPL.TXT at the root of this distribution.
// By using this software in any fashion, you are agreeing to be bound by 
// the terms of this license.
//
// You must not remove this notice, or any other, from this software.

using System.Configuration.Provider;

namespace mojoPortal.Business.WebHelpers
{
    public abstract class UserPreDeleteHandlerProvider : ProviderBase
    {
        public abstract void UserPreDeleteHandler(
            object sender,
            UserPreDeleteEventArgs e);
    }
}
