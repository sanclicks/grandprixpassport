# 📊 GrandPrixPassport — Data Sources & API Registry

## F1 Race Data

| API | URL | Cost | Data | Status |
|---|---|---|---|---|
| OpenF1 | openf1.org | Free | Live telemetry, lap times, pit stops, weather | 🔲 Integrate |
| Ergast | ergast.com | Free | Historical results 1950–present | 🔲 Integrate |
| API-Sports F1 | api-sports.io | $50–200/mo | Real-time standings, commercial use | 🔲 Evaluate |
| Sportmonks F1 | sportmonks.com | $50–150/mo | Fast commercial feed | 🔲 Evaluate |

---

## Ticket Data (Affiliate Programs)

| Platform | Commission | API | Apply URL | Status |
|---|---|---|---|---|
| StubHub | 4% | ✅ Yes | affiliate.stubhub.com | 🔲 Apply |
| Vivid Seats | 6% | ✅ Yes | partners.vividseats.com | 🔲 Apply |
| SeatGeek | 1% | ✅ Yes | seatgeek.com/partners | 🔲 Apply |
| Official F1 | TBD | Partial | formula1.com/affiliate | 🔲 Apply |

---

## Travel Data (Affiliate Programs)

| Platform | Commission | Apply URL | Status |
|---|---|---|---|
| Booking.com | 25–40% | booking.com/affiliate | 🔲 Apply |
| Hotels.com | 4–6% | hotels.com/affiliate | 🔲 Apply |
| Skyscanner | CPC | partners.skyscanner.net | 🔲 Apply |
| GetYourGuide | 8% | partner.getyourguide.com | 🔲 Apply |
| Viator | 8% | viatorforoperators.com | 🔲 Apply |

---

## Maps & Location

| API | Cost | Use Case | Status |
|---|---|---|---|
| Google Maps | Free up to $200/mo | Circuit maps, directions | 🔲 Set up |
| OpenStreetMap | Free | Circuit track layouts | 🔲 Integrate |
| Mapbox | Generous free tier | Custom map styling | 🔲 Evaluate |
| OpenWeatherMap | Free tier | Race weekend forecasts | 🔲 Integrate |

---

## Community & Social Data

| Platform | API Cost | Use Case | Status |
|---|---|---|---|
| Reddit | Free tier | F1 fan sentiment, tips | 🔲 Integrate |
| X (Twitter) | $100/mo Basic | Real-time F1 buzz | 🔲 Evaluate |
| YouTube Data | Free tier | Embed race content | 🔲 Integrate |
| Instagram | Free | User photo embedding | 🔲 Evaluate |

---

## Data Pipeline Architecture

```
EventBridge (every 15 min)
    ↓
Lambda: price-aggregator
    ↓
Fetch: StubHub API + Vivid Seats + SeatGeek
    ↓
Compare: new price vs stored price
    ↓
If price dropped AND user has alert set:
    → SQS queue → Lambda: alert-sender → SES/SNS → User
    ↓
Store: DynamoDB (current price + 90-day history)
```

---

## API Keys Storage

All API keys stored in AWS Secrets Manager.
Never in code, never in environment variables in plain text.

```
/grandprixpassport/prod/openf1/api-key
/grandprixpassport/prod/stubhub/client-id
/grandprixpassport/prod/stubhub/client-secret
/grandprixpassport/prod/stripe/secret-key
/grandprixpassport/prod/claude/api-key
/grandprixpassport/prod/google-maps/api-key
```

---

*Last updated: May 2026*
