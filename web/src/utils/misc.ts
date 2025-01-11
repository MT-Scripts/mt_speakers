export const isEnvBrowser = (): boolean => !(window as any).invokeNative

export const noop = () => {}

export const getVehicleImage = async (model: string): Promise<string> => {
    const localImagePath = `https://cfx-nui-mt_dealerships/vehiclesImages/${model}.png`
    const localImage = new Image()
    localImage.src = localImagePath

    return new Promise((resolve) => {
        localImage.onload = () => {
            resolve(localImagePath)
        }
        localImage.onerror = async () => {
            const websiteImagePath = `https://gta-images.s3.fr-par.scw.cloud/vehicle/${model}.webp`
            const websiteImage = new Image()
            websiteImage.src = websiteImagePath

            websiteImage.onload = () => {
                resolve(websiteImagePath)
            }
            websiteImage.onerror = () => {
                resolve('')
            }
        }
    })
}

interface Vehicle {
    model: string
    name: string
    brand: string
    price: number
    category: string
    shop: string
    stock?: number
    class?: string
    seats?: string
    weight?: number
}

type VehiclesArray = {
    [key: string]: Vehicle[]
}

export const sortVehiclesByLowestPrice = (vehiclesArray: VehiclesArray): Vehicle[] => {
    const flatArray = Object.values(vehiclesArray).flat()
    flatArray.sort((a, b) => a.price - b.price)
    return flatArray
}

export const formatPrice = (amount: number, currency: string): string => {
    return Intl.NumberFormat('en-US', { style: 'currency', currency: currency, minimumFractionDigits: 0, maximumFractionDigits: 0 }).format(amount)
}