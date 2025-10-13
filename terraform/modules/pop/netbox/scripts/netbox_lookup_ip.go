package main

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"strconv"
	"strings"
	"time"
)

type lookupInput struct {
	NetBoxURL   string `json:"netbox_url"`
	NetBoxToken string `json:"netbox_token"`
	Address     string `json:"address"`
}

type lookupOutput struct {
	ID    string `json:"id"`
	Error string `json:"error,omitempty"`
}

func main() {
	out := lookupOutput{ID: ""}

	raw, err := io.ReadAll(os.Stdin)
	if err != nil {
		out.Error = fmt.Sprintf("read input: %v", err)
		emit(out)
		return
	}

	var in lookupInput
	if err := json.Unmarshal(raw, &in); err != nil {
		out.Error = fmt.Sprintf("parse input: %v", err)
		emit(out)
		return
	}

	in.NetBoxURL = strings.TrimSpace(in.NetBoxURL)
	in.NetBoxToken = strings.TrimSpace(in.NetBoxToken)
	in.Address = strings.TrimSpace(in.Address)

	if in.NetBoxURL == "" || in.NetBoxToken == "" || in.Address == "" {
		out.Error = "netbox_url, netbox_token, and address are required"
		emit(out)
		return
	}

	base := strings.TrimRight(in.NetBoxURL, "/")
	if !strings.HasSuffix(base, "/api") {
		base = base + "/api"
	}

	queryURL := fmt.Sprintf("%s/ipam/ip-addresses/?address=%s", base, url.QueryEscape(in.Address))

	req, err := http.NewRequest(http.MethodGet, queryURL, nil)
	if err != nil {
		out.Error = fmt.Sprintf("build request: %v", err)
		emit(out)
		return
	}
	req.Header.Set("Authorization", "Token "+in.NetBoxToken)
	req.Header.Set("Accept", "application/json")

	client := &http.Client{Timeout: 10 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		out.Error = fmt.Sprintf("request failed: %v", err)
		emit(out)
		return
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		out.Error = fmt.Sprintf("read response: %v", err)
		emit(out)
		return
	}

	if resp.StatusCode != http.StatusOK {
		out.Error = fmt.Sprintf("netbox status %d: %s", resp.StatusCode, truncate(string(body), 256))
		emit(out)
		return
	}

	var payload struct {
		Results []struct {
			ID int `json:"id"`
		} `json:"results"`
	}

	if err := json.Unmarshal(body, &payload); err != nil {
		out.Error = fmt.Sprintf("decode response: %v", err)
		emit(out)
		return
	}

	if len(payload.Results) > 0 {
		out.ID = strconv.Itoa(payload.Results[0].ID)
	}

	emit(out)
}

func emit(out lookupOutput) {
	data, err := json.Marshal(out)
	if err != nil {
		fmt.Printf("{\"id\":\"\",\"error\":\"marshal output: %v\"}\n", err)
		return
	}
	fmt.Println(string(data))
}

func truncate(s string, max int) string {
	if len(s) <= max {
		return s
	}
	return s[:max]
}
