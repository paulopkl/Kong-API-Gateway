import { check } from "k6";
import http from "k6/http";

const KONG_CLIENT = "kong";
const KONG_SECRET = "5HqqwY4dlgG69cJC3QFMflBzQJP8iP8O";
const USER = "paulo";
const PASS = "paulo123";

const KEYCLOAK_HOST = "keycloak.iam";
const KUBERNETES_KONG_HOST = "kong-kong-proxy.kong";

export const options = {
    stages: [
        { target: 20, duration: "10s" },
        { target: 30, duration: "60s" },
        { target: 40, duration: "60s" },
        { target: 50, duration: "180s" },
    ],
};

function authenticateUsingKeycloak(clientId, clientSecret, username, pass) {
    const response = http.post(
        `http://${KEYCLOAK_HOST}/realms/bets/protocol/openid-connect/token`,
        {
            client_id: clientId,
            grant_type: "password",
            username: username,
            password: pass,
            client_secret: clientSecret,
            scope: "openid",
        },
        {
            headers: {
                "Content-Type": "application/x-www-form-urlencoded"
            }
        }
    );

    return response.json();
}

export function setup() {
    return authenticateUsingKeycloak(KONG_CLIENT, KONG_SECRET, USER, PASS);
}

export default function (data) {
    const payload = JSON.stringify({
        match: "1X-DC",
        email: "joe@doe.com",
        championship: "Uefa Champions League",
        awayTeamScore: "2",
        homeTeamScore: "3",
    });

    let response = http.post(
        `http://${KUBERNETES_KONG_HOST}/api/bets`,
        payload,
        {
            headers: {
                "Content-Type": "application/json",
                Authorization: `Bearer ${data.access_token}`, // or `Bearer ${clientAuthResp.access_token}`
            },
        }
    );
    
    check(response, {
        "is status 201": (r) => r.status === 201,
    });
}
