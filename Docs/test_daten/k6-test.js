import http from 'k6/http';
import { check, sleep } from 'k6';
import { Counter } from 'k6/metrics';

export let errorCounter = new Counter('errors');

export const options = {
	stages: [
		{ duration: '1m', target: 1 }, // 1 Nutzer
		{ duration: '1m', target: 2 }, // 2 Nutzer
		{ duration: '1m', target: 4 }, // 4 Nutzer
		{ duration: '1m', target: 5 }, // 5 Nutzer
		{ duration: '1m', target: 20 }, // 20 Nutzer
	],
};

const BASE_URL = 'https://smartender-432708816033.europe-west3.run.app';
const API_KEY = 'b0ec1aa3-98bd-434d-b6b6-f72b99383859';

function randomString(length) {
	const chars = 'abcdefghijklmnopqrstuvwxyz1234567890';
	let result = '';
	for (let i = 0; i < length; i++) {
		result += chars.charAt(Math.floor(Math.random() * chars.length));
	}
	return result;
}

function generateMacAddress() {
	const hex = '0123456789ABCDEF';
	let mac = [];
	for (let i = 0; i < 6; i++) {
		mac.push(
			hex.charAt(Math.floor(Math.random() * 16)) + hex.charAt(Math.floor(Math.random() * 16))
		);
	}
	return mac.join(':');
}

export default function () {
	// 1. Registrierung
	const username = `user_${randomString(8)}`;
	const password = 'Password123!';
	const email = `${username}@example.com`;

	let registerRes = http.post(
		`${BASE_URL}/api/auth/register`,
		JSON.stringify({
			username,
			password,
			email,
		}),
		{
			headers: { 'Content-Type': 'application/json', 'X-API-Key': API_KEY },
		}
	);

	check(registerRes, { 'User registration successful': (res) => res.status === 201 });
	if (registerRes.status !== 201) return;

	// 2. Login
	let loginRes = http.post(
		`${BASE_URL}/api/auth/login`,
		JSON.stringify({
			username,
			password,
		}),
		{
			headers: { 'Content-Type': 'application/json', 'X-API-Key': API_KEY },
		}
	);

	check(loginRes, { 'User login successful': (res) => res.status === 200 });
	if (loginRes.status !== 200) return;

	const loginData = JSON.parse(loginRes.body);
	const jwt = loginData.token;
	const userId = parseInt(loginData.userID);

	// 3. Hardware registrieren
	//
	let hardwareRes = http.post(
		`${BASE_URL}/smartender/register`,
		JSON.stringify({
			hardware_name: `Hardware_${randomString(5)}`,
			mac_address: generateMacAddress(),
			user_id: userId,
		}),
		{
			headers: {
				'X-API-Key': API_KEY,
				Authorization: `Bearer ${jwt}`,
			},
		}
	);

	check(hardwareRes, { 'Hardware registration successful': (res) => res.status === 200 });
	const hardwareData = JSON.parse(hardwareRes.body);
	const hardwareId = hardwareData.hardwareID;

	// 4. Drinks anlegen
	let drinks = [];
	for (let i = 0; i < 10; i++) {
		let drinkRes = http.post(
			`${BASE_URL}/api/user/hardware/${hardwareId}/drinks`,
			JSON.stringify({
				drink_name: `Drink_${randomString(5)}`,
				is_alcoholic: Math.random() > 0.5,
			}),
			{
				headers: {
					'Content-Type': 'application/json',
					'X-API-Key': API_KEY,
					Authorization: `Bearer ${jwt}`,
				},
			}
		);

		check(drinkRes, { 'Drink creation successful': (res) => res.status === 201 });
		if (drinkRes.status === 201) drinks.push(JSON.parse(drinkRes.body));
	}

	// 5. Slots befüllen
	for (let i = 0; i < Math.min(drinks.length, 5); i++) {
		let setSlotRes = http.put(
			`${BASE_URL}/api/user/hardware/${hardwareId}/slots/${i + 1}`,
			JSON.stringify({
				drink_id: drinks[i].drink_id,
			}),
			{
				headers: {
					'Content-Type': 'application/json',
					'X-API-Key': API_KEY,
					Authorization: `Bearer ${jwt}`,
				},
			}
		);

		check(setSlotRes, { 'Slot set successfully': (res) => res.status === 204 });
	}

	// 6. Rezepte anlegen
	let recipes = [];
	for (let i = 0; i < 10; i++) {
		let recipeRes = http.post(
			`${BASE_URL}/api/user/hardware/${hardwareId}/recipes`,
			JSON.stringify({
				recipe_name: `Recipe_${randomString(5)}`,
				picture_id: Math.floor(Math.random() * 100),
			}),
			{
				headers: {
					'Content-Type': 'application/json',
					'X-API-Key': API_KEY,
					Authorization: `Bearer ${jwt}`,
				},
			}
		);

		check(recipeRes, { 'Recipe creation successful': (res) => res.status === 201 });
		if (recipeRes.status === 201) recipes.push(JSON.parse(recipeRes.body));
	}

	// 7. Zutaten zu Rezepten hinzufügen
	for (let i = 0; i < recipes.length; i++) {
		// Füge jedem Rezept bis zu 3 Zutaten hinzu, falls genügend Drinks vorhanden sind
		for (let j = 0; j < Math.min(3, drinks.length); j++) {
			let addIngredientRes = http.post(
				`${BASE_URL}/api/user/hardware/${hardwareId}/recipes/${recipes[i].recipe_id}/ingredients`,
				JSON.stringify({
					drink_id: drinks[j].drink_id,
					quantity_ml: Math.floor(Math.random() * 100) + 50, // Zufällige Menge zwischen 50 und 150 ml
				}),
				{
					headers: {
						'Content-Type': 'application/json',
						'X-API-Key': API_KEY,
						Authorization: `Bearer ${jwt}`,
					},
				}
			);

			check(addIngredientRes, {
				'Ingredient added successfully': (res) => res.status === 201,
			});
			if (addIngredientRes.status !== 201) {
				errorCounter.add(1);
				console.error(
					`Failed to add ingredient to recipe ${recipes[i].recipe_id}:`,
					addIngredientRes.body
				);
			}
		}
	}

	// 8. Favoriten erstellen
	for (let i = 0; i < Math.min(recipes.length, 3); i++) {
		let favoriteRes = http.post(
			`${BASE_URL}/api/user/hardware/${hardwareId}/favorite/${recipes[i].recipe_id}`,
			{},
			{
				headers: {
					'Content-Type': 'application/json',
					'X-API-Key': API_KEY,
					Authorization: `Bearer ${jwt}`,
				},
			}
		);

		check(favoriteRes, { 'Favorite created successfully': (res) => res.status === 201 });
	}

	// 9. Slots abrufen
	let getSlotsRes = http.get(`${BASE_URL}/api/user/hardware/${hardwareId}/slots`, {
		headers: {
			'X-API-Key': API_KEY,
			Authorization: `Bearer ${jwt}`,
		},
	});

	let slots = JSON.parse(getSlotsRes.body);

	check(getSlotsRes, { 'Get slots returned an array': () => Array.isArray(slots) });

	// 10. Favoriten abrufen
	let getFavoritesRes = http.get(`${BASE_URL}/api/user/hardware/${hardwareId}/favorites`, {
		headers: { 'X-API-Key': API_KEY, Authorization: `Bearer ${jwt}` },
	});
	let favorites = JSON.parse(getFavoritesRes.body);
	check(getFavoritesRes, { 'Get favorites returned an array': () => Array.isArray(favorites) });

	// Pause zwischen den Aktionen
	sleep(1);
}
