# Nexus Project Status

## 1. Folder Structure

| Directory/File | Purpose |
|----------------|---------|
| `lib/main.dart` | Application entry point and routing host |
| `lib/models/` | Data structures for API payloads and local storage |
| `lib/screens/` | Primary feature screens and route destinations |
| `lib/services/` | Data layer, API fetching, and device capabilities |
| `lib/theme/` | Global visual styling, colors, and gradients |
| `lib/widgets/` | Reusable UI components shared across multiple screens |

---

## 2. Screens

| Screen Name | Status | APIs Used | Key Dependencies |
|-------------|--------|-----------|------------------|
| **HomeScreen** | ✅ Done | None | `CarouselCard` |
| **AirPulseScreen** | ✅ Done | Open-Meteo (Weather/AQI), Geocoding API | `WeatherService`, `AirQualityService`, `GeocodingService`, `LocationStorageService` |
| **CosmicLensScreen**| ✅ Done | NASA APOD (Single & Range) | `NasaService`, `ApodHeroCard`, `ApodDetailScreen` |
| **ApodDetailScreen**| ✅ Done | None (Uses Passed Data) | `ApodHeroCard` |
| **EchoesScreen** | ✅ Done | Wikipedia "On This Day" | `WikiService` |
| **OrbitWatchScreen**| ✅ Done | ISS Tracker (WhereTheISS & OpenNotify) | `IssService`, `flutter_map` |

*(Note: All API-driven screens rely heavily on `ConnectivityService`, `LoadingState`, and `ErrorState`)*

---

## 3. Navigation Map

* **HomeScreen**
  * Tapping "Air Pulse" ➡️ **AirPulseScreen**
  * Tapping "Cosmic Lens" ➡️ **CosmicLensScreen**
  * Tapping "Echoes" ➡️ **EchoesScreen**
  * Tapping "Orbit Watch" ➡️ **OrbitWatchScreen**

* **CosmicLensScreen**
  * Tapping a "Previous Day" grid card ➡️ **ApodDetailScreen**
  * Tapping the Hero Image ➡️ **FullscreenImageViewer**

* **ApodDetailScreen**
  * Tapping the Hero Image ➡️ **FullscreenImageViewer**

*(All detail/feature screens route back to their previous screen via a top-left back button)*

---

## 4. Data Layer

| Service | Primary Functions | Error Handling | Timeouts / Caching |
|---------|-------------------|----------------|--------------------|
| `AirQualityService` | `fetchAirQuality()` | Yes | None |
| `ConnectivityService`| `hasInternetConnection()` | Yes | None |
| `GeocodingService` | `searchCities()` | Yes | None |
| `IssService` | `fetchIssPosition()` | Yes | **4-second Timeout**, Fallback API |
| `LocationStorage` | `getLastLocation()`, `getSavedLocations()` | Yes | **Local Persistence** (`shared_preferences`) |
| `NasaService` | `fetchApod()`, `fetchApodRange()` | Yes | None |
| `WeatherService` | `fetchWeather()` | Yes | None |
| `WikiService` | `fetchOnThisDayEvents()` | Yes | None |

**Data Layer Inconsistencies:**
* Only `IssService` explicitly defines a request timeout (`.timeout()`). Other services rely on the default OS HTTP timeout, which can cause infinite loading UI hangs if the network drops mid-request.
* There is no unified HTTP wrapper. Each service independently parses JSON and handles its own HTTP errors.

---

## 5. Shared Widgets & Utilities

* **`ApodHeroCard`**: Used by `CosmicLensScreen` and `ApodDetailScreen` to render the complex APOD layout and interactive modal sheet.
* **`CarouselCard`**: Used by `HomeScreen` to build the 3D perspective menu.
* **`ErrorState`**: Used across all feature screens to provide a consistent retry-button UI on failure.
* **`LoadingState`**: Used across all feature screens for a consistent, themed loading spinner.
* **`FullscreenImageViewer`**: Used by `ApodHeroCard` to provide a pinch-to-zoom experience for APOD images.

---

## 6. Technical Debt & Inconsistencies

1. **Deprecated Methods**: Over 25 instances of `withOpacity(x)` are used across the project. In newer Flutter versions, this is deprecated and should be replaced with `withValues(alpha: x)` to avoid static analysis warnings.
2. **Missing Caching Strategy**: Highly static data (like NASA's APOD or Wikipedia's historical events) is fetched from the network every time the screen is opened. Implementing a lightweight cache would vastly improve UX.
3. **UI Duplication**: The frosted circular "Back Button" is duplicated manually in the `SafeArea` of almost every screen, sometimes with different `Hero` tags or layout properties.
4. **Missing Timeouts**: As noted above, most HTTP requests lack explicit timeouts, risking locked UI states on spotty connections.

---

## 7. Prioritized Next Steps

1. **Refactor Deprecations**: Run a project-wide search and replace for `withOpacity` ➡️ `withValues`.
2. **Standardize HTTP**: Create an `ApiClient` utility class that handles timeouts, unified error catching, and JSON decoding to remove boilerplate from the individual services.
3. **Widget Extraction**: Extract the frosted glass back button into `lib/widgets/frosted_back_button.dart` and use it uniformly across all screens.
4. **Implement Request Caching**: Add a simple memory cache to `NasaService` and `WikiService` so users don't have to re-download today's image or history events every time they toggle between screens.
