# Prime Creatives Portfolio

Modern, full-featured portfolio website for Aliu Micheal Imodu — Graphic Designer & Brand Identity Specialist.

## Features

- **Beautiful Hero Section** with auto-rotating background images
- **Project Portfolio** with filtering and detailed case studies
- **Service Showcase** with comprehensive service descriptions
- **Testimonials Carousel** with auto-play and navigation
- **Experience Timeline** displaying work history
- **Admin Dashboard** with PIN-based authentication
- **Supabase Integration** for dynamic content management
- **Fully Responsive** design for all devices
- **SEO Optimized** with Schema.org structured data
- **WhatsApp Integration** for direct communication

## Files

- `index.html` - Main portfolio website (rename from primecreatives.html)
- `admin.html` - Admin dashboard for content management
- `setup-database.sql` - Supabase database setup script

## Setup Instructions

### 1. Supabase Configuration

1. Create a Supabase project at [supabase.com](https://supabase.com)
2. Copy your project URL and Publishable Key
3. Update the credentials in `admin.html` and `index.html`
4. Enable **Anonymous Sign-Ins** in Authentication settings
5. Run `setup-database.sql` in the SQL Editor

### 2. Storage Setup

The project uses Supabase Storage for project images:
- Bucket name: `project-images`
- Visibility: Public
- Auto-created by the setup script

### 3. Environment Variables

Update these in both HTML files:
```javascript
const SUPABASE_URL = "your-project-url";
const SUPABASE_PUBLISHABLE_KEY = "your-publishable-key";
```

### 4. Admin PIN

Default PIN: **0110**

The admin panel auto-authenticates with this PIN on first visit. For production, change this value in:
- `admin.html` - `const FIXED_PIN = "0110"`

## Deployment

### Vercel (Recommended)

```bash
git push origin main
```

Connect your GitHub repo to Vercel for automatic deployments.

### Other Platforms

- **Netlify**: Drag and drop `index.html` and `admin.html`
- **GitHub Pages**: Push to main branch
- **Traditional Hosting**: Upload files to your server

## Customization

### Update Personal Info

In `index.html`, update:
- Name and title
- Contact information (WhatsApp, email, phone)
- Social media links
- Professional bio

### Add Projects

Use the admin dashboard at `/admin.html` to:
- Upload project images
- Add case studies
- Set featured projects
- Manage categories

### Manage Services

All services are manageable through the admin dashboard.

## Browser Support

- Chrome 90+
- Firefox 88+
- Safari 14+
- Edge 90+

## Performance

- Lazy-loaded images
- Optimized CSS and JavaScript
- Minimal external dependencies
- Fast page load times

## Security

- Server-side PIN verification
- Row-level security on all tables
- Anonymous authentication
- No sensitive data in client code

## Support

For issues or questions:
- Email: imodumicheal519@gmail.com
- WhatsApp: +234 905 953 8257

## License

© 2026 Prime Creatives. All rights reserved.
