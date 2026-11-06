const PH_BOUNDS = { minLat: 4, maxLat: 22, minLon: 115, maxLon: 130 };
const CACHE_TTL_MS = 5 * 60_000;
const STALE_CACHE_MS = 24 * 60 * 60_000;

export const ALERT_SOURCE_REGISTRY = [
  {
    id: 'pagasa',
    name: 'DOST-PAGASA',
    authority: 'Philippine government',
    mode: 'verification-link',
    url: 'https://www.pagasa.dost.gov.ph/',
    coverage: ['weather', 'tropical-cyclone', 'flood', 'marine'],
    note: 'No documented stable public alert API or RSS contract was verified.',
  },
  {
    id: 'phivolcs',
    name: 'DOST-PHIVOLCS',
    authority: 'Philippine government',
    mode: 'verification-link',
    url: 'https://www.phivolcs.dost.gov.ph/',
    coverage: ['earthquake', 'volcano', 'tsunami'],
    note: 'Official bulletin pages are linked; HTML is not scraped.',
  },
  {
    id: 'ndrrmc',
    name: 'NDRRMC',
    authority: 'Philippine government',
    mode: 'verification-link',
    url: 'https://ndrrmc.gov.ph/',
    coverage: ['situation-report', 'multi-hazard'],
    note: 'Situation reports are primarily web pages and documents.',
  },
  {
    id: 'mgb',
    name: 'DENR-MGB',
    authority: 'Philippine government',
    mode: 'verification-link',
    url: 'https://mgb.gov.ph/',
    coverage: ['landslide', 'flood', 'geohazard'],
    note: 'Hazard maps are not treated as current alerts.',
  },
  {
    id: 'usgs',
    name: 'USGS Earthquake Catalog',
    authority: 'United States government',
    mode: 'documented-api',
    url: 'https://earthquake.usgs.gov/fdsnws/event/1/',
    coverage: ['earthquake'],
  },
  {
    id: 'eonet',
    name: 'NASA EONET',
    authority: 'United States government',
    mode: 'documented-api',
    url: 'https://eonet.gsfc.nasa.gov/docs/v3',
    coverage: ['storm', 'flood', 'landslide', 'volcano', 'wildfire'],
  },
  {
    id: 'gdacs',
    name: 'GDACS',
    authority: 'United Nations / European Commission',
    mode: 'documented-api',
    url: 'https://www.gdacs.org/gdacsapi/swagger/index.html',
    coverage: ['multi-hazard'],
  },
];

function inside(point) {
  return point &&
    point.latitude >= PH_BOUNDS.minLat &&
    point.latitude <= PH_BOUNDS.maxLat &&
    point.longitude >= PH_BOUNDS.minLon &&
    point.longitude <= PH_BOUNDS.maxLon;
}

async function getJson(fetchImpl, url) {
  let lastError;
  for (let attempt = 0; attempt < 2; attempt += 1) {
    try {
      const response = await fetchImpl(url, {
        headers: { accept: 'application/json', 'user-agent': 'Kalasag/1.0' },
        signal: AbortSignal.timeout(10_000),
      });
      if (!response.ok) throw new Error('HTTP ' + response.status);
      return await response.json();
    } catch (error) {
      lastError = error;
      if (attempt === 0) {
        await new Promise((resolve) => setTimeout(resolve, 250));
      }
    }
  }
  throw lastError;
}

function commonAlert({
  id,
  title,
  description,
  issuedAt,
  updatedAt,
  severity,
  officialLevel = '',
  agency,
  category,
  sourceUrl,
  coordinates,
  affectedAreas = [],
  lifecycle = 'active',
  referenceNumber = '',
  retrievedAt,
}) {
  return {
    id,
    title,
    description,
    issuedAt: new Date(issuedAt).toISOString(),
    updatedAt: updatedAt ? new Date(updatedAt).toISOString() : null,
    effectiveAt: null,
    expiresAt: null,
    retrievedAt: retrievedAt.toISOString(),
    visualPriority: severity,
    officialLevel,
    agency,
    category,
    sourceUrl,
    coordinates,
    affectedAreas,
    actions: ['Monitor Philippine authorities and follow local evacuation instructions.'],
    referenceNumber,
    verificationStatus: 'supplementary',
    lifecycle,
    language: 'en',
    isCached: false,
  };
}

export async function fetchUsgs(fetchImpl, now = new Date()) {
  const start = new Date(now.getTime() - 3 * 24 * 60 * 60_000).toISOString();
  const query = new URLSearchParams({
    format: 'geojson',
    starttime: start,
    minlatitude: String(PH_BOUNDS.minLat),
    maxlatitude: String(PH_BOUNDS.maxLat),
    minlongitude: String(PH_BOUNDS.minLon),
    maxlongitude: String(PH_BOUNDS.maxLon),
    minmagnitude: '3.5',
    orderby: 'time',
  });
  const data = await getJson(
    fetchImpl,
    'https://earthquake.usgs.gov/fdsnws/event/1/query?' + query,
  );
  return (data.features ?? []).map((feature) => {
    const properties = feature.properties ?? {};
    const coordinates = feature.geometry?.coordinates ?? [];
    const magnitude = Number(properties.mag ?? 0);
    return commonAlert({
      id: 'usgs-' + feature.id,
      title: 'M' + magnitude.toFixed(1) + ' Earthquake',
      description:
        (properties.place ?? 'Philippines region') +
        ' at a depth of ' +
        Number(coordinates[2] ?? 0).toFixed(1) +
        ' km.',
      issuedAt: Number(properties.time ?? properties.updated ?? now.getTime()),
      updatedAt: Number(properties.updated ?? properties.time ?? now.getTime()),
      severity:
        magnitude >= 6 ? 'Critical' : magnitude >= 5 ? 'High' : magnitude >= 4 ? 'Medium' : 'Low',
      officialLevel: 'Magnitude ' + magnitude.toFixed(1),
      agency: 'USGS',
      category: 'earthquake',
      sourceUrl: properties.url ?? 'https://earthquake.usgs.gov/',
      coordinates: {
        latitude: Number(coordinates[1]),
        longitude: Number(coordinates[0]),
        label: properties.place ?? 'Epicenter',
      },
      affectedAreas: properties.place ? [properties.place] : [],
      referenceNumber: String(feature.id ?? ''),
      retrievedAt: now,
    });
  });
}

export async function fetchEonet(fetchImpl, now = new Date()) {
  const query = new URLSearchParams({
    bbox: '115,22,130,4',
    days: '30',
    status: 'open',
    limit: '100',
  });
  const data = await getJson(
    fetchImpl,
    'https://eonet.gsfc.nasa.gov/api/v3/events?' + query,
  );
  const categories = {
    floods: 'flood',
    severeStorms: 'weather',
    landslides: 'landslide',
    volcanoes: 'volcano',
    wildfires: 'wildfire',
  };
  return (data.events ?? []).flatMap((event) => {
    const categoryId = event.categories?.[0]?.id;
    const category = categories[categoryId];
    const geometry = event.geometry?.at(-1);
    const raw = geometry?.coordinates;
    if (!category || !Array.isArray(raw) || raw.length < 2) return [];
    const point = {
      latitude: Number(raw[1]),
      longitude: Number(raw[0]),
      label: 'Reported event location',
    };
    if (!inside(point)) return [];
    const source = event.sources?.[0];
    return [
      commonAlert({
        id: 'eonet-' + event.id,
        title: event.title ?? 'Natural event',
        description:
          event.description ?? 'Natural event tracked within the Philippine area.',
        issuedAt: geometry.date ?? now,
        severity:
          categoryId === 'severeStorms' || categoryId === 'volcanoes' ? 'High' : 'Medium',
        agency: 'NASA EONET',
        category,
        sourceUrl: source?.url ?? event.link ?? 'https://eonet.gsfc.nasa.gov/',
        coordinates: point,
        referenceNumber: String(event.id ?? ''),
        retrievedAt: now,
      }),
    ];
  });
}

export async function fetchGdacs(fetchImpl, now = new Date()) {
  const data = await getJson(
    fetchImpl,
    'https://www.gdacs.org/gdacsapi/api/events/geteventlist/events4app',
  );
  return (data.features ?? []).flatMap((feature) => {
    const properties = feature.properties ?? {};
    const raw = feature.geometry?.coordinates;
    const point = Array.isArray(raw) && raw.length >= 2
      ? { latitude: Number(raw[1]), longitude: Number(raw[0]), label: 'Event location' }
      : null;
    const country = String(
      properties.country ?? properties.affectedcountries ?? '',
    ).toLowerCase();
    if (!country.includes('philippine') && !inside(point)) return [];
    const type = String(properties.eventtype ?? '').toUpperCase();
    const category =
      type === 'EQ' ? 'earthquake' :
      type === 'VO' ? 'volcano' :
      type === 'WF' ? 'wildfire' :
      type === 'FL' ? 'flood' :
      'weather';
    const level = String(properties.alertlevel ?? '').toLowerCase();
    const severity =
      level === 'red' ? 'Critical' :
      level === 'orange' ? 'High' :
      level === 'green' ? 'Medium' :
      'Low';
    return [
      commonAlert({
        id: 'gdacs-' + (properties.eventid ?? properties.id),
        title: properties.eventname ?? properties.name ?? 'Disaster report',
        description: String(
          properties.description ?? properties.severitytext ?? 'Event affecting the Philippines.',
        ).replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim(),
        issuedAt: properties.fromdate ?? properties.todate ?? now,
        updatedAt: properties.todate ?? null,
        severity,
        officialLevel: properties.alertlevel ? 'GDACS ' + properties.alertlevel : '',
        agency: 'GDACS',
        category,
        sourceUrl: properties.url ?? 'https://www.gdacs.org/',
        coordinates: inside(point) ? point : null,
        referenceNumber: String(properties.eventid ?? properties.id ?? ''),
        retrievedAt: now,
      }),
    ];
  });
}

export function normalizeAlerts(alerts) {
  const byKey = new Map();
  for (const alert of alerts) {
    const day = String(alert.issuedAt).slice(0, 10);
    const title = alert.title.toLowerCase().replace(/[^a-z0-9]+/g, ' ').trim();
    const key = alert.category + ':' + title + ':' + day;
    const current = byKey.get(key);
    if (!current || String(alert.updatedAt ?? alert.issuedAt) >
        String(current.updatedAt ?? current.issuedAt)) {
      byKey.set(key, alert);
    }
  }
  const rank = { Critical: 4, High: 3, Medium: 2, Low: 1 };
  return [...byKey.values()].sort((a, b) => {
    const priority = (rank[b.visualPriority] ?? 0) - (rank[a.visualPriority] ?? 0);
    return priority || String(b.issuedAt).localeCompare(String(a.issuedAt));
  });
}

export function createAlertAggregator({
  fetchImpl = globalThis.fetch,
  now = () => new Date(),
  providers = [
    ['usgs', 'USGS Earthquake Catalog', fetchUsgs],
    ['eonet', 'NASA EONET', fetchEonet],
    ['gdacs', 'GDACS', fetchGdacs],
  ],
} = {}) {
  let cache;

  return {
    async getAlerts({ force = false } = {}) {
      const requestedAt = now();
      if (!force && cache && requestedAt - cache.storedAt < CACHE_TTL_MS) {
        return { ...cache.payload, cache: { status: 'fresh', ageSeconds: 0 } };
      }

      const outcomes = await Promise.all(
        providers.map(async ([id, name, provider]) => {
          const checkedAt = now();
          try {
            const alerts = await provider(fetchImpl, checkedAt);
            return {
              alerts,
              source: { id, name, available: true, checkedAt: checkedAt.toISOString(), message: '' },
            };
          } catch (error) {
            return {
              alerts: [],
              source: {
                id,
                name,
                available: false,
                checkedAt: checkedAt.toISOString(),
                message: 'Provider unavailable: ' + String(error?.message ?? 'unknown error'),
              },
            };
          }
        }),
      );

      const alerts = normalizeAlerts(outcomes.flatMap((outcome) => outcome.alerts));
      const sources = outcomes.map((outcome) => outcome.source);
      if (!alerts.length && sources.every((source) => !source.available)) {
        if (cache && requestedAt - cache.storedAt < STALE_CACHE_MS) {
          return {
            ...cache.payload,
            sources,
            cache: {
              status: 'stale',
              ageSeconds: Math.floor((requestedAt - cache.storedAt) / 1000),
            },
          };
        }
        throw new Error('all_alert_providers_unavailable');
      }

      const payload = {
        alerts,
        sources,
        retrievedAt: requestedAt.toISOString(),
        registry: ALERT_SOURCE_REGISTRY,
        cache: { status: 'miss', ageSeconds: 0 },
      };
      cache = { payload, storedAt: requestedAt };
      return payload;
    },
  };
}
