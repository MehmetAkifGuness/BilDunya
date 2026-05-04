/**
 * Pin oluşturma — backend POST /pins
 * API_BASE_URL: trailing slash olmadan, örn. https://api.example.com
 */

const API_BASE_URL = 'BURAYA_BACKEND_URL';

export { API_BASE_URL };

/**
 * @param {{
 *   title: string,
 *   description: string,
 *   image?: string | null,
 *   lat: number,
 *   lng: number,
 *   userId: string,
 * }} params
 */
export async function createPinRequest({
  title,
  description,
  image = null,
  lat,
  lng,
  userId,
}) {
  try {
    const payload = {
      title,
      description,
      image,
      lat: Number(lat),
      lng: Number(lng),
      userId,
    };

    console.log('PIN CREATE REQUEST:', payload);

    const response = await fetch(`${API_BASE_URL}/pins`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(payload),
    });

    const rawText = await response.text();
    let data = null;
    if (rawText) {
      try {
        data = JSON.parse(rawText);
      } catch (jsonError) {
        console.log('PIN CREATE JSON PARSE ERROR:', jsonError);
        data = { _raw: rawText };
      }
    }

    console.log('PIN CREATE RESPONSE STATUS:', response.status);
    console.log('PIN CREATE RESPONSE BODY:', data);

    if (!response.ok) {
      const backendMessage =
        (data && (data.message || data.error)) ||
        (typeof data?._raw === 'string' && data._raw.trim().slice(0, 240)) ||
        response.statusText ||
        `Pin eklenemedi. Sunucu kodu: ${response.status}`;

      throw new Error(backendMessage);
    }

    return data;
  } catch (error) {
    console.log('PIN CREATE REQUEST ERROR:', error);

    if (error.message === 'Network request failed') {
      throw new Error(
        'Backend sunucusuna ulaşılamıyor. API adresini ve internet bağlantısını kontrol edin.',
      );
    }

    throw error;
  }
}
