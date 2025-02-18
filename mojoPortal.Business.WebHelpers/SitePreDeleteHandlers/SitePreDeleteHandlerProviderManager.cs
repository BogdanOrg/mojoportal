﻿using System;
using System.Configuration.Provider;
using System.Web.Configuration;
using log4net;

namespace mojoPortal.Business.WebHelpers;
public sealed class SitePreDeleteHandlerProviderManager
{
	private static object initializationLock = new object();
	private static readonly ILog log = LogManager.GetLogger(typeof(SitePreDeleteHandlerProviderManager));

	static SitePreDeleteHandlerProviderManager()
	{
		Initialize();
	}

	private static void Initialize()
	{
		providerCollection = new SitePreDeleteProviderCollection();

		try
		{
			SitePreDeleteHandlerProviderConfig config = SitePreDeleteHandlerProviderConfig.GetConfig();

			if (config != null)
			{

				if (
					(config.Providers == null)
					|| (config.Providers.Count < 1)
					)
				{
					throw new ProviderException("No SitePreDeleteProviderCollection found.");
				}

				ProvidersHelper.InstantiateProviders(config.Providers, providerCollection, typeof(SitePreDeleteHandlerProvider));
			}
			else
			{
				// config was null, not a good thing
				log.Error("SitePreDeleteProviderCollection could not be loaded so empty provider collection was returned");

			}
		}
		catch (NullReferenceException ex)
		{
			log.Error(ex);
		}
		catch (TypeInitializationException ex)
		{
			log.Error(ex);
		}
		catch (ProviderException ex)
		{
			log.Error(ex);
		}

		providerCollection.SetReadOnly();
	}

	private static SitePreDeleteProviderCollection providerCollection;

	public static SitePreDeleteProviderCollection Providers
	{
		get
		{
			if (providerCollection == null) Initialize();
			return providerCollection;

		}
	}

}