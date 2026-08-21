const DEFAULT_INSTALLATION_NAME = 'Arles';

export const replaceVisibleBrandNames = (
  text,
  installationName = DEFAULT_INSTALLATION_NAME
) => {
  if (typeof text !== 'string') return text;

  return text.replace(/\b(?:Chatwoot|Nexus)\b/g, installationName);
};

export const replaceVisibleBrandNamesInTranslation = text => {
  const installationName =
    (typeof window !== 'undefined' &&
      window.globalConfig?.INSTALLATION_NAME) ||
    DEFAULT_INSTALLATION_NAME;

  return replaceVisibleBrandNames(text, installationName);
};
